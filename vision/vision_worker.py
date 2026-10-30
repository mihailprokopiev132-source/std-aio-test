"""
STD-AIO vision worker.

Captures the Roblox client area and publishes template detections as TSV.
This process only observes the screen; it never sends mouse or keyboard input.
"""
from __future__ import annotations

import argparse
import os
import re
import sys
import tempfile
import time
from pathlib import Path

try:
    import cv2
    import mss
    import numpy as np
    import psutil
except ImportError as exc:
    print(f"Missing vision dependency: {exc.name}. Install requirements-vision.txt.", file=sys.stderr)
    raise SystemExit(2)

import ctypes
from ctypes import wintypes

USER32 = ctypes.WinDLL("user32", use_last_error=True)
PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
IMAGE_FILE_NAME = 0

class RECT(ctypes.Structure):
    _fields_ = [("left", wintypes.LONG), ("top", wintypes.LONG),
                ("right", wintypes.LONG), ("bottom", wintypes.LONG)]

class POINT(ctypes.Structure):
    _fields_ = [("x", wintypes.LONG), ("y", wintypes.LONG)]

ENUMPROC = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)

USER32.IsWindowVisible.argtypes = [wintypes.HWND]
USER32.IsWindowVisible.restype = wintypes.BOOL
USER32.GetWindowThreadProcessId.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.DWORD)]
USER32.GetWindowThreadProcessId.restype = wintypes.DWORD
USER32.GetClientRect.argtypes = [wintypes.HWND, ctypes.POINTER(RECT)]
USER32.GetClientRect.restype = wintypes.BOOL
USER32.ClientToScreen.argtypes = [wintypes.HWND, ctypes.POINTER(POINT)]
USER32.ClientToScreen.restype = wintypes.BOOL
USER32.EnumWindows.argtypes = [ENUMPROC, wintypes.LPARAM]
USER32.EnumWindows.restype = wintypes.BOOL
USER32.SetProcessDPIAware.argtypes = []
USER32.SetProcessDPIAware.restype = wintypes.BOOL


def enable_dpi_awareness():
    try:
        USER32.SetProcessDPIAware()
    except Exception:
        pass


def find_roblox_client(target_hwnd=0):
    """Return the requested Roblox client area, or the largest one if unspecified."""
    pids = set()
    for proc in psutil.process_iter(["pid", "name"]):
        try:
            if (proc.info.get("name") or "").lower() == "robloxplayerbeta.exe":
                pids.add(int(proc.info["pid"]))
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    if not pids:
        return None

    found = []

    def visit(hwnd, _):
        if target_hwnd and int(hwnd) != target_hwnd:
            return True
        if not USER32.IsWindowVisible(hwnd):
            return True
        pid = wintypes.DWORD()
        USER32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
        if pid.value not in pids:
            return True
        rect = RECT()
        if not USER32.GetClientRect(hwnd, ctypes.byref(rect)):
            return True
        width, height = rect.right - rect.left, rect.bottom - rect.top
        if width < 320 or height < 240:
            return True
        origin = POINT(0, 0)
        if not USER32.ClientToScreen(hwnd, ctypes.byref(origin)):
            return True
        found.append((int(hwnd), int(origin.x), int(origin.y), int(width), int(height)))
        return True

    USER32.EnumWindows(ENUMPROC(visit), 0)
    if not found:
        return None
    # Prefer the largest visible Roblox client window.
    return max(found, key=lambda item: item[3] * item[4])


def load_templates(folder: Path):
    templates = []
    folder.mkdir(parents=True, exist_ok=True)
    for path in sorted(folder.iterdir()):
        if path.suffix.lower() != ".png":
            continue
        image = cv2.imread(str(path), cv2.IMREAD_GRAYSCALE)
        if image is None or image.size == 0:
            continue
        if not path.stem.isascii() or not re.fullmatch(r"[A-Za-z0-9_-]{1,64}", path.stem):
            continue
        height, width = image.shape[:2]
        if width < 5 or height < 5 or float(image.std()) < 1.0:
            continue
        templates.append((path.stem, image))
    return templates


def detect(frame_bgr, templates, threshold):
    gray = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2GRAY)
    frame_h, frame_w = gray.shape[:2]
    hits = []
    for name, template in templates:
        th, tw = template.shape[:2]
        if tw > frame_w or th > frame_h:
            continue
        scores = cv2.matchTemplate(gray, template, cv2.TM_CCOEFF_NORMED)
        # A small per-template cap avoids flooding the consumer with duplicates.
        for _ in range(5):
            _, score, _, location = cv2.minMaxLoc(scores)
            if not np.isfinite(score) or score < threshold:
                break
            x, y = location
            hits.append((name, int(x), int(y), int(tw), int(th), float(score)))
            pad_x, pad_y = max(3, tw // 2), max(3, th // 2)
            x1, y1 = max(0, x - pad_x), max(0, y - pad_y)
            x2, y2 = min(scores.shape[1], x + pad_x + 1), min(scores.shape[0], y + pad_y + 1)
            scores[y1:y2, x1:x2] = -1.0
    hits.sort(key=lambda item: (-item[5], item[1], item[2], item[0]))
    return hits


def publish(path: Path, status: str, origin, dimensions, hits):
    """Atomically replace the TSV so readers never see a half-written frame."""
    left, top = origin
    width, height = dimensions
    rows = [f"FRAME\t{int(time.time() * 1000)}\t{left}\t{top}\t{width}\t{height}",
            f"STATUS\t{status}"]
    rows.extend(
        f"HIT\t{name}\t{x}\t{y}\t{w}\t{h}\t{score:.4f}"
        for name, x, y, w, h, score in hits
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=path.name, suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as stream:
            stream.write("\n".join(rows) + "\n")
        os.replace(temp_name, path)
    finally:
        try:
            if os.path.exists(temp_name):
                os.unlink(temp_name)
        except OSError:
            pass


def main():
    parser = argparse.ArgumentParser(description="STD-AIO read-only OpenCV vision worker")
    parser.add_argument("--templates", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--stop-file", type=Path, required=True)
    parser.add_argument("--hwnd", type=int, default=0, help="Exact Roblox top-level window handle")
    parser.add_argument("--fps", type=float, default=8.0)
    parser.add_argument("--threshold", type=float, default=0.82)
    parser.add_argument("--once", action="store_true")
    args = parser.parse_args()

    if os.name != "nt":
        raise SystemExit("The Roblox window capture backend currently requires Windows.")
    if not 1.0 <= args.fps <= 20.0:
        raise SystemExit("--fps must be between 1 and 20.")
    if not 0.50 <= args.threshold <= 0.99:
        raise SystemExit("--threshold must be between 0.50 and 0.99.")

    enable_dpi_awareness()
    templates = load_templates(args.templates)
    interval = 1.0 / args.fps

    with mss.mss() as capture:
        while not args.stop_file.exists():
            started = time.perf_counter()
            window = find_roblox_client(args.hwnd)
            if window is None:
                publish(args.output, "ROBLOX_NOT_FOUND", (0, 0), (0, 0), [])
            else:
                hwnd, left, top, width, height = window
                try:
                    shot = capture.grab({"left": left, "top": top, "width": width, "height": height})
                    frame = np.asarray(shot)[:, :, :3]
                    hits = detect(frame, templates, args.threshold) if templates else []
                    status = "OK" if templates else "NO_TEMPLATES"
                    publish(args.output, status, (left, top), (width, height), hits)
                except Exception as exc:
                    publish(args.output, f"CAPTURE_ERROR:{type(exc).__name__}", (left, top), (width, height), [])

            if args.once:
                break
            remaining = interval - (time.perf_counter() - started)
            if remaining > 0:
                time.sleep(remaining)


if __name__ == "__main__":
    main()

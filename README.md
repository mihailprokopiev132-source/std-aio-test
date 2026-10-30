# STD-AIO

Development build for Sorcerer Tower Defense.

## Architecture

- **GUI.ahk** — AutoHotkey v2 control panel and main entry point.
- **Engine.ahk** — guarded timer loop; pauses actions unless Roblox is foreground.
- **VisionBridge.ahk** — starts/stops the Python worker and reads fresh detections.
- **vision/vision_worker.py** — Windows client-area capture and OpenCV template matching.
- **GameState.ahk** — template-based state detection with transition confirmation.
- **ImageRecognition.ahk** — OpenCV first, built-in AHK ImageSearch fallback.
- **Input.ahk** — input restricted to the Roblox client area and focused window.
- **AutoFarm / AutoPlace / AutoUpgrade / AutoSkip** — state-gated automation modules.
- **Capture.csproj** — optional DWM thumbnail preview helper; it does not provide recognition frames.

## Requirements

- Windows 10/11
- AutoHotkey v2.0
- Roblox client
- Python 3.10+ (optional, for OpenCV recognition)
- .NET 8 SDK (optional, for the DWM preview helper)

## Setup and run

Use **GUI.ahk** as the main application entry point. `STD-AIO.ahk` is the earlier standalone preview prototype.

1. Keep the repository files and `config.ini` together.
2. Install AutoHotkey v2.
3. For OpenCV recognition, install Python 3.10+ and run:
   `python -m pip install -r requirements-vision.txt`
4. Capture your own PNG templates from the current game UI and put them in `Templates/`.
5. Use template filenames containing only letters, numbers, underscores, or hyphens, for example `state_match.png`.
6. Configure placement coordinates in `config.ini` only after checking them against your Roblox client resolution.
7. Run `GUI.ahk` and press START.
8. Switch to Roblox. The engine waits until Roblox is the foreground window before sending input.

If Python or the OpenCV dependencies are unavailable, the engine falls back to AHK ImageSearch. The optional preview helper can be built with `dotnet build Capture.csproj --configuration Debug` from the repository root.

## Templates

See [Templates/README.txt](Templates/README.txt) for the required state and action markers. The worker currently scans PNG files only.

## Vision worker

The worker is read-only: it captures the Roblox client area and recognizes templates; it never sends mouse or keyboard input. It runs at 8 FPS with a default similarity threshold of 0.82 and publishes detections atomically to `runtime/vision.tsv`. The AHK bridge accepts only fresh results. If the worker fails or stops updating, the engine stops it and falls back to ImageSearch.

The capture backend reads visible desktop pixels. Minimized, obscured, or GPU-protected rendering is not guaranteed to be captured correctly.

## Safety and current module scope

- Unknown game state means **no automation actions**; recognized state changes must be stable for two consecutive scans.
- Automatic actions only run in a recognized lobby or match.
- Auto Start Match is limited to clicking the lobby start control; it does not manage farming waves or strategy.
- Auto Upgrade requires both a selected-unit marker and an upgrade-available marker. It does not choose units or priorities.
- Auto Skip requires its availability marker.
- Auto Place reads up to 20 manually configured client-area coordinates and attempts one placement per engine tick. Its default count is zero.
- The engine stops if the Roblox window disappears and pauses while another window is active.
- Missing templates and unrecognized states do not trigger guessed coordinates or blind clicks.

## Limitations

This is an integration scaffold, **not a finished game-specific bot**. No official game UI templates, verified placement coordinates, unit priorities, currency OCR, wave OCR, or map-specific strategy are bundled. OCR has not yet been implemented.

## Configuration

`config.ini` stores module toggles, interval, mode, and up to 20 placement entries. Placement count defaults to 0, so no unit placement occurs until configured.

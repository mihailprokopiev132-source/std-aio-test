# STD-AIO

Development build for Sorcerer Tower Defense.

## Current architecture

- **GUI.ahk** — AutoHotkey v2 control panel.
- **Engine.ahk** — guarded timer loop; pauses actions unless Roblox is foreground.
- **GameState.ahk** — template-based state detection.
- **ImageRecognition.ahk** — PNG template matching in the visible Roblox client area.
- **Input.ahk** — mouse and key input restricted to the Roblox client area and focused window.
- **AutoFarm / AutoPlace / AutoUpgrade / AutoSkip** — state-gated automation modules.
- **Capture.csproj** — optional DWM thumbnail preview helper. DWM preview is not a raw image-frame API.

## Requirements

- Windows 10/11
- AutoHotkey v2.0
- Roblox client
- Optional: .NET 8 SDK to build the preview helper

## Run

Use **`GUI.ahk`** as the main application entry point. `STD-AIO.ahk` is the earlier standalone screen-preview prototype and is not the integrated engine.

1. Keep the AHK files and `config.ini` in the same folder.
2. Install AutoHotkey v2.
3. Install the optional OpenCV dependencies with `python -m pip install -r requirements-vision.txt`.
4. Capture your own PNG templates from the current game UI and put them in `Templates/`.
5. Keep template filenames to letters, numbers, underscores, or hyphens (for example `state_match.png`).
4. Configure placement coordinates in `config.ini` only after checking them against your Roblox client resolution.
5. Run `GUI.ahk` and press START.
6. Switch to Roblox. The engine waits until Roblox is the foreground window before sending input.

To build the optional DWM preview helper locally, run `dotnet build Capture.csproj --configuration Debug` from the repository root. The main automation engine does not require this preview helper.

## Template names

See [Templates/README.txt](Templates/README.txt) for all state and action markers.

## Safety and behavior

- Unknown game state means **no automation actions**; recognized state changes must be stable for two consecutive scans.
- Automatic actions only run in the recognized lobby or match state.
- Upgrade and skip require separate availability markers; upgrade also requires a selected-unit marker.
- Only one configured placement is attempted per engine tick.
- The engine stops if the Roblox window disappears and pauses while another window is active.
- Template clicks target the center of the matched image.
- Missing templates are treated as unavailable actions; no default coordinates are guessed.

## Important limitations

This is an integration scaffold, **not a finished game-specific bot**. No official game UI templates, verified placement coordinates, unit priorities, currency OCR, wave OCR, or map-specific strategy are bundled. You must create templates from your own current game screenshots.

The integrated Python/OpenCV worker captures the Roblox client area and publishes detections through an atomic TSV file. The AHK bridge consumes fresh detections; if the worker cannot start or stops updating, the engine falls back to built-in ImageSearch. DWM Thumbnail remains preview-only and is not used as the recognition source.

## Vision worker\n\nThe worker is read-only: it captures and recognizes images but never sends input. Install dependencies using the command above. It scans PNG templates in `Templates/`, uses an 0.82 similarity threshold at 8 FPS, and writes current detections under `runtime/vision.tsv`. If Python or its dependencies are unavailable, the AHK engine falls back to ImageSearch. The capture backend requires Windows and captures visible desktop pixels; minimized or obscured game rendering is not guaranteed.\n\n## Module scope

- Auto Start Match is the current limited AutoFarm behavior; it clicks the lobby start control only. It does not yet manage farming waves or unit strategy.
- Auto Upgrade acts only when a unit-selected marker and an upgrade-available marker are both detected. It does not choose units or priorities.
- Auto Skip acts only when its availability marker is detected.
- Auto Place reads up to 20 manually configured client-area coordinates and attempts one placement per tick. The default count is zero.

## Configuration

`config.ini` stores module toggles, interval, mode, and up to 20 placement entries. Placement count defaults to 0, so no unit placement occurs until configured.

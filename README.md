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
- Optional: .NET 8 Windows Desktop Runtime / SDK to build the preview helper

## Run

1. Keep the AHK files and `config.ini` in the same folder.
2. Install AutoHotkey v2.
3. Capture your own PNG templates from the current game UI and put them in `Templates/`.
4. Configure placement coordinates in `config.ini` only after checking them against your Roblox client resolution.
5. Run `GUI.ahk`, open Roblox, activate its window, and press START.

## Template names

See [Templates/README.txt](Templates/README.txt) for all state and action markers.

## Safety and behavior

- Unknown game state means **no automation actions**.
- Automatic actions only run in the recognized lobby or match state.
- Upgrade and skip require separate availability markers; upgrade also requires a selected-unit marker.
- Only one configured placement is attempted per engine tick.
- The engine stops if the Roblox window disappears and pauses while another window is active.
- Template clicks target the center of the matched image.
- Missing templates are treated as unavailable actions; no default coordinates are guessed.

## Important limitations

This is an integration scaffold, **not a finished game-specific bot**. No official game UI templates, verified placement coordinates, unit priorities, currency OCR, wave OCR, or map-specific strategy are bundled. You must create templates from your own current game screenshots.

The existing Python/OpenCV detector files found in the project library are a separate prototype and are not yet wired into this AutoHotkey engine. The current engine uses AutoHotkey ImageSearch. DWM Thumbnail is preview-only and does not expose frame pixels to the AHK modules.

## Configuration

`config.ini` stores module toggles, interval, mode, and up to 20 placement entries. Placement count defaults to 0, so no unit placement occurs until configured.

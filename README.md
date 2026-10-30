# STD-AIO

Development integration branch for Sorcerer Tower Defense.

## Requirements
- Windows 10/11
- AutoHotkey v2.0
- Roblox client

## Start
1. Keep all AHK files in the repository root.
2. Install AutoHotkey v2.
3. Run GUI.ahk.
4. Open Roblox and activate its window before pressing START.
5. Add your own PNG UI templates to Templates/.

## Integrated
- Shared GUI-driven engine loop and persistent config.ini settings.
- Input limited to the Roblox window and only while Roblox is focused.
- ImageSearch for user-provided templates in the visible Roblox client area.
- Module cooldowns; AutoPlace count is 0 by default.

## Limitations
This is an integration scaffold, not a finished game-specific bot. No game UI templates, placement coordinates, unit selection logic, currency OCR, wave-state model, or upgrade priorities are included yet. These must be derived from actual Sorcerer Tower Defense screenshots. The C# DWM helper is preview-only; ImageSearch currently checks the visible client area directly.

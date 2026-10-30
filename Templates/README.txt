STD-AIO uses user-captured PNG templates. Capture each marker from your own current Sorcerer Tower Defense UI.

GAME STATE MARKERS:
- state_lobby.png — a stable, unique element visible in the lobby.
- state_match.png — a stable, unique element visible only during an active match.
- state_menu.png — optional main menu marker.
- state_victory.png — victory/result screen marker.
- state_defeat.png — defeat/result screen marker.

ACTIONS:
- start_match.png — start/queue control. Clicked only when state_lobby is detected.
- placement_ready.png — marker that indicates the placement UI is ready.
- unit_selected.png — visible marker confirming a unit is selected.
- upgrade_available.png — marker that confirms an upgrade can be purchased.
- upgrade_button.png — upgrade control; clicked only after both upgrade markers are found.
- skip_available.png — marker confirming wave skip is currently available.
- skip_wave.png — skip control; clicked only after skip_available is found.

IMPORTANT:
- Templates must be PNG files and should be tightly cropped around stable UI elements.
- Avoid animated, changing, translucent, or overlapping areas.
- Use the same Roblox display scale and resolution you plan to play with.
- Do not create state markers from similar-looking UI elements; each state marker must be unique.
- Unknown state disables all modules. If no marker is detected, the engine will wait.
- Do not enable automatic placement until placement coordinates and slot keys have been checked.
- The engine currently uses ImageSearch, not OpenCV or OCR. The Python detector is a separate prototype.

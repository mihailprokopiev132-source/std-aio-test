#Requires AutoHotkey v2.0

global CurrentGameState := "Unknown"
global PreviousGameState := "Unknown"

DetectGameState() {
    ; User-captured visual markers; no game-specific UI assumptions are embedded.
    states := [
        ["state_victory", "Victory"],
        ["state_defeat", "Defeat"],
        ["state_match", "InMatch"],
        ["state_lobby", "Lobby"],
        ["state_menu", "Menu"]
    ]
    for entry in states
        if FindTemplate(entry[1], &x, &y)
            return entry[2]
    return "Unknown"
}

UpdateGameState() {
    global CurrentGameState, PreviousGameState, AutoPlaceDone, ModuleCooldowns
    detected := DetectGameState()
    if detected = CurrentGameState
        return detected

    PreviousGameState := CurrentGameState
    CurrentGameState := detected
    AddLog("Game state: " PreviousGameState " -> " CurrentGameState)

    if CurrentGameState = "InMatch" && PreviousGameState != "InMatch"
        AutoPlaceDone := Map()
    if CurrentGameState = "Lobby" && PreviousGameState != "Lobby"
        ModuleCooldowns := Map()
    return CurrentGameState
}

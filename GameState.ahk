#Requires AutoHotkey v2.0

global CurrentGameState := "Unknown"
global PreviousGameState := "Unknown"
global PendingGameState := ""
global PendingGameStateCount := 0

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
    global PendingGameState, PendingGameStateCount

    detected := DetectGameState()

    ; Unknown or a one-frame transition blocks actions immediately without
    ; resetting per-match progress. A new positive state needs two consecutive hits.
    if detected = "Unknown" {
        PendingGameState := ""
        PendingGameStateCount := 0
        return "Unknown"
    }

    if detected != PendingGameState {
        PendingGameState := detected
        PendingGameStateCount := 1
        return "Unknown"
    }

    PendingGameStateCount += 1
    if PendingGameStateCount < 2
        return "Unknown"

    if detected = CurrentGameState
        return CurrentGameState

    PreviousGameState := CurrentGameState
    CurrentGameState := detected
    AddLog("Game state: " PreviousGameState " -> " CurrentGameState)

    if CurrentGameState = "InMatch" && PreviousGameState != "InMatch"
        AutoPlaceDone := Map()
    if CurrentGameState = "Lobby" && PreviousGameState != "Lobby"
        ModuleCooldowns := Map()

    return CurrentGameState
}

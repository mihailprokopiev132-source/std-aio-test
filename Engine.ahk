#Requires AutoHotkey v2.0

global EngineBusy := false
global ModuleCooldowns := Map()

EngineStart() {
    global IsRunning, RobloxHwnd, Settings, StartButton, StopButton
    global CurrentGameState, PreviousGameState, AutoPlaceDone, ModuleCooldowns
    if IsRunning
        return true

    hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !hwnd {
        AddLog("Engine start rejected: Roblox was not found.")
        DetectRoblox()
        return false
    }
    RobloxHwnd := hwnd
    ; The GUI button takes focus when clicked. Start safely, then wait until Roblox is foreground.

    IsRunning := true
    ModuleCooldowns := Map()
    AutoPlaceDone := Map()
    CurrentGameState := "Unknown"
    PreviousGameState := "Unknown"
    StartButton.Enabled := false
    StopButton.Enabled := true
    UpdateStatus("RUNNING")
    SetTimer(EngineTick, Settings["CaptureInterval"])
    AddLog("Engine started. Activate Roblox to allow game input. Interval: " Settings["CaptureInterval"] " ms.")
    return true
}

EngineStop(reason := "Macro stopped.") {
    global IsRunning, StartButton, StopButton
    SetTimer(EngineTick, 0)
    IsRunning := false
    if IsSet(StartButton)
        StartButton.Enabled := true
    if IsSet(StopButton)
        StopButton.Enabled := false
    UpdateStatus("IDLE")
    AddLog(reason)
}

EngineTick() {
    global IsRunning, EngineBusy, Settings, RobloxHwnd
    if !IsRunning || EngineBusy
        return
    EngineBusy := true
    try {
        if !RobloxHwnd || !WinExist("ahk_id " RobloxHwnd) {
            EngineStop("Roblox window lost. Engine stopped.")
            return
        }
        if !WinActive("ahk_id " RobloxHwnd)
            return

        state := UpdateGameState()
        UpdateGameStateStatus(state)
        if state = "Lobby" && Settings["AutoFarm"]
            AutoFarm_Tick(state)
        if state = "InMatch" {
            if Settings["AutoPlace"]
                AutoPlace_Tick(state)
            if Settings["AutoUpgrade"]
                AutoUpgrade_Tick(state)
            if Settings["AutoSkip"]
                AutoSkip_Tick(state)
        }
    } catch as err {
        AddLog("Engine error: " err.Message)
        EngineStop("Engine stopped after an error.")
    } finally {
        EngineBusy := false
    }
}

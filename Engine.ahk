#Requires AutoHotkey v2.0
global EngineBusy := false
global ModuleCooldowns := Map()
EngineStart() {
    global IsRunning, RobloxHwnd, Settings, StartButton, StopButton, AutoPlaceDone
    if IsRunning
        return true
    hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !hwnd {
        AddLog("Engine start rejected: Roblox was not found.")
        DetectRoblox()
        return false
    }
    RobloxHwnd := hwnd
    if !WinActive("ahk_id " RobloxHwnd) {
        AddLog("Activate Roblox before starting.")
        return false
    }
    IsRunning := true
    ModuleCooldowns := Map()
    AutoPlaceDone := Map()
    StartButton.Enabled := false
    StopButton.Enabled := true
    UpdateStatus("RUNNING")
    SetTimer(EngineTick, Settings["CaptureInterval"])
    AddLog("Engine started. Interval: " Settings["CaptureInterval"] " ms.")
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
        if Settings["AutoFarm"]
            AutoFarm_Tick()
        if Settings["AutoPlace"]
            AutoPlace_Tick()
        if Settings["AutoUpgrade"]
            AutoUpgrade_Tick()
        if Settings["AutoSkip"]
            AutoSkip_Tick()
    } catch as err {
        AddLog("Engine error: " err.Message)
        EngineStop("Engine stopped after an error.")
    } finally {
        EngineBusy := false
    }
}

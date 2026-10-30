
#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Config.ahk
#Include Input.ahk
#Include ImageRecognition.ahk
#Include GameState.ahk
#Include AutoFarm.ahk
#Include AutoPlace.ahk
#Include AutoUpgrade.ahk
#Include AutoSkip.ahk
#Include Engine.ahk

global Settings := LoadSettings()

; ==========================================
; STD-AIO | Sorcerer Tower Defense
; Version 0.1.2
; ==========================================

global AppName := "STD-AIO"
global AppVersion := "0.1.2"

global IsRunning := false
global IsCapturing := false
global RobloxHwnd := 0
global CaptureHwnd := 0
global CapturePid := 0
global CurrentMode := "Solo"

global CaptureExe := A_ScriptDir
    . "\bin\Debug\net8.0-windows10.0.19041.0\Capture.exe"

; ==========================================
; GUI
; ==========================================

global MainGui := Gui("+Resize +MinSize800x600", AppName)
MainGui.BackColor := "15171D"
MainGui.SetFont("s10 cFFFFFF", "Segoe UI")

MainGui.SetFont("s20 Bold cFFFFFF")
MainGui.AddText("x20 y15 w400 h35", "STD-AIO")

MainGui.SetFont("s9 cA0A6B5")
MainGui.AddText("x22 y49 w400 h20", "SORCERER TOWER DEFENSE | v" AppVersion)

global MainStatus := MainGui.AddText(
    "x590 y27 w190 h25 Center",
    "STATUS: IDLE"
)

; ==========================================
; TABS
; ==========================================

global Tabs := MainGui.AddTab3(
    "x15 y85 w770 h460",
    ["Dashboard", "Capture", "Auto Farm", "Settings", "Logs"]
)

; ==========================================
; DASHBOARD
; ==========================================

Tabs.UseTab(1)

MainGui.SetFont("s13 Bold cFFFFFF")
MainGui.AddText("x35 y135 w700 h30", "Control Center")

MainGui.SetFont("s10 cA0A6B5")
MainGui.AddText("x35 y175 w150 h20", "GAME STATUS")

global GameStatus := MainGui.AddText(
    "x35 y200 w300 h30 cFF7777",
    "Roblox: Not detected"
)

MainGui.AddText("x35 y250 w150 h20", "GAME MODE")

global ModeSelect := MainGui.AddDropDownList(
    "x35 y275 w180 Choose" (Settings["GameMode"] = "Multiplayer" ? 2 : 1),
    ["Solo", "Multiplayer"]
)

MainGui.AddText("x35 y325 w150 h20", "MACRO CONTROL")

global StartButton := MainGui.AddButton(
    "x35 y355 w140 h40",
    "START"
)

global StopButton := MainGui.AddButton(
    "x190 y355 w140 h40 Disabled",
    "STOP"
)

global DetectButton := MainGui.AddButton(
    "x35 y415 w295 h35",
    "DETECT ROBLOX"
)

MainGui.AddText("x390 y175 w300 h25", "CURRENT CONFIGURATION")

global ConfigInfo := MainGui.AddText(
    "x390 y210 w300 h120",
    "Mode: Solo`nRecognition: ImageSearch`nCapture: Stopped"
)
global GameStateStatus := MainGui.AddText("x390 y340 w300 h25", "Game state: Unknown")

; ==========================================
; CAPTURE
; ==========================================

Tabs.UseTab(2)

MainGui.SetFont("s13 Bold cFFFFFF")
MainGui.AddText("x35 y135 w500 h30", "Screen Capture")

MainGui.SetFont("s10 cA0A6B5")
MainGui.AddText("x35 y175 w300 h20", "ROBLOX WINDOW PREVIEW")

global PreviewBox := MainGui.AddText(
    "x35 y205 w500 h250 Border Center +0x200",
    "PREVIEW NOT AVAILABLE"
)

global CaptureStatus := MainGui.AddText(
    "x35 y470 w500 h25",
    "Capture: Stopped"
)

global CaptureButton := MainGui.AddButton(
    "x565 y205 w180 h35",
    "START CAPTURE"
)

global StopCaptureButton := MainGui.AddButton(
    "x565 y250 w180 h35 Disabled",
    "STOP CAPTURE"
)

MainGui.AddText("x565 y295 w180 h20", "CAPTURE METHOD")

global CaptureMethod := MainGui.AddDropDownList(
    "x565 y320 w180 Choose1 Disabled",
    ["DWM Thumbnail"]
)

; ==========================================
; AUTO FARM
; ==========================================

Tabs.UseTab(3)

MainGui.SetFont("s13 Bold cFFFFFF")
MainGui.AddText("x35 y135 w500 h30", "Automation")

MainGui.SetFont("s10 cA0A6B5")
MainGui.AddText("x35 y180 w250 h20", "AUTOMATION MODULES")

global FarmCheck := MainGui.AddCheckbox(
    "x35 y215 " (Settings["AutoFarm"] ? "Checked" : ""),
    "Enable Auto Start Match"
)

global UpgradeCheck := MainGui.AddCheckbox(
    "x35 y250 " (Settings["AutoUpgrade"] ? "Checked" : ""),
    "Enable Auto Upgrade"
)

global WaveCheck := MainGui.AddCheckbox(
    "x35 y285 " (Settings["AutoSkip"] ? "Checked" : ""),
    "Enable Auto Skip Wave"
)

global AutoPlaceCheck := MainGui.AddCheckbox(
    "x35 y320 " (Settings["AutoPlace"] ? "Checked" : ""),
    "Enable Auto Place"
)

MainGui.AddText("x390 y180 w250 h20", "MODULE STATUS")

global ModuleStatus := MainGui.AddText(
    "x390 y215 w300 h120",
    "Auto Start Match: Ready`nAuto Upgrade: Ready`nAuto Skip: Disabled`nAuto Place: Ready"
)

; ==========================================
; SETTINGS
; ==========================================

Tabs.UseTab(4)

MainGui.SetFont("s13 Bold cFFFFFF")
MainGui.AddText("x35 y135 w500 h30", "Settings")

MainGui.SetFont("s10 cA0A6B5")
MainGui.AddText("x35 y180 w250 h20", "RECOGNITION")

global RecognitionSelect := MainGui.AddDropDownList(
    "x35 y210 w200 Choose1",
    ["ImageSearch"]
)

MainGui.AddText("x35 y260 w250 h20", "CAPTURE INTERVAL (MS)")

global IntervalInput := MainGui.AddEdit(
    "x35 y290 w200 Number",
    String(Settings["CaptureInterval"])
)

global SaveSettingsButton := MainGui.AddButton(
    "x35 y350 w200 h35",
    "SAVE SETTINGS"
)

; ==========================================
; LOGS
; ==========================================

Tabs.UseTab(5)

MainGui.SetFont("s13 Bold cFFFFFF")
MainGui.AddText("x35 y135 w500 h30", "Event Log")

global LogBox := MainGui.AddEdit(
    "x35 y175 w700 h270 ReadOnly -Wrap",
    "[STD-AIO] Initialized.`r`n"
)

global ClearLogButton := MainGui.AddButton(
    "x35 y460 w150 h35",
    "CLEAR LOGS"
)

Tabs.UseTab()

; ==========================================
; FOOTER
; ==========================================

MainGui.SetFont("s9 c777F90")
MainGui.AddText(
    "x20 y555 w750 h20",
    "STD-AIO | Sorcerer Tower Defense | Development Build"
)

; ==========================================
; EVENTS
; ==========================================

StartButton.OnEvent("Click", StartMacro)
StopButton.OnEvent("Click", StopMacro)
DetectButton.OnEvent("Click", DetectRoblox)

CaptureButton.OnEvent("Click", StartCapture)
StopCaptureButton.OnEvent("Click", StopCapture)

ClearLogButton.OnEvent("Click", ClearLogs)
SaveSettingsButton.OnEvent("Click", SaveSettings)

ModeSelect.OnEvent("Change", UpdateMode)
Tabs.OnEvent("Change", TabChanged)

MainGui.OnEvent("Size", MainGuiResized)
MainGui.OnEvent("Close", MainWindowClose)

RecognitionSelect.Choose(1)
ConfigInfo.Text := "Mode: " Settings["GameMode"] "`nRecognition: " Settings["RecognitionMethod"] "`nCapture: Stopped"
MainGui.Show("w800 h600")

AddLog("STD-AIO initialized.")

; ==========================================
; MACRO CONTROL
; ==========================================

StartMacro(*) {
    EngineStart()
}

StopMacro(*) {
    EngineStop("Macro stopped by user.")
}

; ==========================================
; ROBLOX DETECTION
; ==========================================

DetectRoblox(*) {
    global RobloxHwnd, GameStatus

    hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")

    if hwnd {
        RobloxHwnd := hwnd

        GameStatus.Text := "Roblox: Detected"
        GameStatus.SetFont("c77DD77")

        AddLog("Roblox window detected.")
    } else {
        RobloxHwnd := 0

        GameStatus.Text := "Roblox: Not detected"
        GameStatus.SetFont("cFF7777")

        AddLog("Roblox window not found.")
    }
}

; ==========================================
; CAPTURE CONTROL
; ==========================================

StartCapture(*) {
    global RobloxHwnd, IsCapturing
    global CaptureStatus, CaptureButton, StopCaptureButton
    global CaptureExe, CaptureHwnd, CapturePid, MainGui

    if IsCapturing
        return

    DetectRoblox()

    if !RobloxHwnd
        return

    if !FileExist(CaptureExe) {
        MsgBox(
            "Capture.exe not found.`n`n" CaptureExe
            . "`n`nBuild the C# project first.",
            "STD-AIO"
        )
        AddLog("Capture.exe not found.")
        return
    }

    try {
        Run('"' CaptureExe '"', A_ScriptDir, "Hide", &CapturePid)
    } catch as err {
        MsgBox("Could not start capture helper.`n" err.Message)
        AddLog("Failed to launch capture helper.")
        return
    }

    CaptureStatus.Text := "Capture: Starting..."

    CaptureHwnd := WinWait("STD-AIO | Live Capture",, 5)

    if !CaptureHwnd {
        CapturePid := 0
        CaptureStatus.Text := "Capture: Helper did not start"
        AddLog("Capture helper window not found.")
        return
    }

    ; Make the preview window owned by the main GUI.
    if A_PtrSize = 8 {
        DllCall(
            "SetWindowLongPtrW",
            "Ptr", CaptureHwnd,
            "Int", -8,
            "Ptr", MainGui.Hwnd,
            "Ptr"
        )
    } else {
        DllCall(
            "SetWindowLongW",
            "Ptr", CaptureHwnd,
            "Int", -8,
            "Ptr", MainGui.Hwnd,
            "Ptr"
        )
    }

    IsCapturing := true

    CaptureButton.Enabled := false
    StopCaptureButton.Enabled := true

    CaptureStatus.Text := "Capture: Live preview connected"

    PositionCaptureOverlay()

    AddLog("DWM capture started.")
}

StopCapture(*) {
    global IsCapturing, CaptureHwnd, CapturePid
    global CaptureStatus, CaptureButton, StopCaptureButton
    global PreviewBox

    IsCapturing := false

    if CaptureHwnd && WinExist("ahk_id " CaptureHwnd) {
        WinClose("ahk_id " CaptureHwnd)
    }

    CaptureHwnd := 0
    CapturePid := 0

    CaptureStatus.Text := "Capture: Stopped"
    PreviewBox.Text := "PREVIEW NOT AVAILABLE"

    CaptureButton.Enabled := true
    StopCaptureButton.Enabled := false

    AddLog("Capture stopped.")
}

; ==========================================
; PREVIEW POSITION
; ==========================================

PositionCaptureOverlay() {
    global IsCapturing, CaptureHwnd
    global MainGui, PreviewBox, Tabs

    if !IsCapturing || !CaptureHwnd
        return

    if !WinExist("ahk_id " CaptureHwnd)
        return

    if Tabs.Value != 2 {
        WinHide("ahk_id " CaptureHwnd)
        return
    }

    WinGetClientPos(&gx, &gy, &gw, &gh, "ahk_id " MainGui.Hwnd)
    ControlGetPos(&x, &y, &w, &h, PreviewBox)

    WinMove(
        gx + x + 1,
        gy + y + 1,
        w - 2,
        h - 2,
        "ahk_id " CaptureHwnd
    )

    WinShow("ahk_id " CaptureHwnd)
}

TabChanged(ctrl, *) {
    PositionCaptureOverlay()
}

MainGuiResized(gui, minMax, *) {
    if minMax = 1 {
        global CaptureHwnd

        if CaptureHwnd
            WinHide("ahk_id " CaptureHwnd)

        return
    }

    PositionCaptureOverlay()
}

MainWindowClose(*) {
    EngineStop("Application closing.")
    StopCapture()
    ExitApp()
}

; ==========================================
; SETTINGS
; ==========================================

SaveSettings(*) {
    try {
        SaveSettingsFromGui()
        ConfigInfo.Text := "Mode: " Settings["GameMode"] "`nRecognition: " Settings["RecognitionMethod"] "`nCapture: " (IsCapturing ? "Running" : "Stopped")
        AddLog("Settings saved to config.ini.")
        if IsRunning {
            SetTimer(EngineTick, 0)
            SetTimer(EngineTick, Settings["CaptureInterval"])
        }
    } catch as err {
        MsgBox(err.Message, "STD-AIO settings")
    }
}

UpdateMode(*) {
    global ModeSelect, CurrentMode, ConfigInfo
    CurrentMode := ModeSelect.Text
    Settings["GameMode"] := CurrentMode
    ConfigInfo.Text := "Mode: " CurrentMode
        . "`nRecognition: " Settings["RecognitionMethod"]
        . "`nCapture: " (IsCapturing ? "Running" : "Stopped")
    AddLog("Mode changed to " CurrentMode ".")
}

; ==========================================
; STATUS AND LOGS
; ==========================================

UpdateStatus(status) {
    global MainStatus

    MainStatus.Text := "STATUS: " status
}

UpdateGameStateStatus(state) {
    global GameStateStatus
    GameStateStatus.Text := "Game state: " state
}

AddLog(message) {
    global LogBox

    timestamp := FormatTime(, "HH:mm:ss")

    LogBox.Value .= "[" timestamp "] " message "`r`n"
}

ClearLogs(*) {
    global LogBox

    LogBox.Value := ""
    AddLog("Logs cleared.")
}

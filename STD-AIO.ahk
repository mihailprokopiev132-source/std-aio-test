
#Requires AutoHotkey v2.0
#SingleInstance Force

global CaptureRunning := false
global CurrentBitmap := 0
global PreviewWidth := 640
global PreviewHeight := 360

MainGui := Gui("+AlwaysOnTop", "STD-AIO v0.2.0")
MainGui.BackColor := "20232A"
MainGui.SetFont("s10 cFFFFFF", "Segoe UI")

MainGui.AddText("x15 y12 w640 Center",
    "STD-AIO | SCREEN CAPTURE ENGINE")

Preview := MainGui.AddPicture(
    "x15 y45 w640 h360 0xE"
)

Status := MainGui.AddText(
    "x15 y415 w400",
    "Status: Waiting"
)

FindButton := MainGui.AddButton(
    "x15 y450 w150 h35",
    "Find Roblox"
)

StartButton := MainGui.AddButton(
    "x180 y450 w150 h35",
    "Start Capture"
)

StopButton := MainGui.AddButton(
    "x345 y450 w150 h35",
    "Stop Capture"
)

FindButton.OnEvent("Click", FindRoblox)
StartButton.OnEvent("Click", StartCapture)
StopButton.OnEvent("Click", StopCapture)

MainGui.OnEvent("Close", (*) => ExitApp())
MainGui.Show("w670 h510")

FindRoblox(*) {
    hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")

    if !hwnd {
        Status.Text := "Roblox not found"
        return
    }

    Status.Text := "Roblox window detected!"
}

StartCapture(*) {
    global CaptureRunning

    if CaptureRunning
        return

    if !WinExist("ahk_exe RobloxPlayerBeta.exe") {
        Status.Text := "Roblox not found!"
        return
    }

    CaptureRunning := true
    Status.Text := "Status: Capturing"

    SetTimer(UpdatePreview, 100)
}

StopCapture(*) {
    global CaptureRunning

    CaptureRunning := false
    SetTimer(UpdatePreview, 0)

    ClearPreview()
    Status.Text := "Status: Stopped"
}

UpdatePreview() {
    global Preview, PreviewWidth, PreviewHeight

    hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")

    if !hwnd {
        Status.Text := "Roblox window lost"
        StopCapture()
        return
    }

    rect := Buffer(16, 0)

    if !DllCall("GetClientRect",
        "Ptr", hwnd, "Ptr", rect)
        return

    width := NumGet(rect, 8, "Int")
    height := NumGet(rect, 12, "Int")

    if width <= 0 || height <= 0
        return

    srcDC := DllCall("GetDC",
        "Ptr", hwnd, "Ptr")

    if !srcDC
        return

    memDC := DllCall("gdi32\CreateCompatibleDC",
        "Ptr", srcDC, "Ptr")

    hBitmap := DllCall(
        "gdi32\CreateCompatibleBitmap",
        "Ptr", srcDC,
        "Int", PreviewWidth,
        "Int", PreviewHeight,
        "Ptr"
    )

    oldObject := DllCall(
        "gdi32\SelectObject",
        "Ptr", memDC,
        "Ptr", hBitmap,
        "Ptr"
    )

    DllCall("gdi32\StretchBlt",
        "Ptr", memDC,
        "Int", 0, "Int", 0,
        "Int", PreviewWidth,
        "Int", PreviewHeight,
        "Ptr", srcDC,
        "Int", 0, "Int", 0,
        "Int", width, "Int", height,
        "UInt", 0x00CC0020
    )

    DllCall("gdi32\SelectObject",
        "Ptr", memDC,
        "Ptr", oldObject,
        "Ptr"
    )

    DllCall("gdi32\DeleteDC", "Ptr", memDC)
    DllCall("ReleaseDC", "Ptr", hwnd, "Ptr", srcDC)

    oldBitmap := DllCall(
        "SendMessageW",
        "Ptr", Preview.Hwnd,
        "UInt", 0x172,
        "Ptr", 0,
        "Ptr", hBitmap,
        "Ptr"
    )

    if oldBitmap
        DllCall("gdi32\DeleteObject", "Ptr", oldBitmap)
}

ClearPreview() {
    global Preview

    oldBitmap := DllCall(
        "SendMessageW",
        "Ptr", Preview.Hwnd,
        "UInt", 0x172,
        "Ptr", 0,
        "Ptr", 0,
        "Ptr"
    )

    if oldBitmap
        DllCall("gdi32\DeleteObject", "Ptr", oldBitmap)
}


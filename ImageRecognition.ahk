#Requires AutoHotkey v2.0

global TemplateDir := A_ScriptDir "\Templates"

FindTemplate(templateName, &foundX := 0, &foundY := 0, variation := 25) {
    global RobloxHwnd, TemplateDir, VisionActive
    foundX := 0
    foundY := 0

    ; Template names are identifiers, never arbitrary file paths.
    if !RegExMatch(templateName, "^[A-Za-z0-9_-]{1,64}$")
        return false
    if !RobloxHwnd || !WinExist("ahk_id " RobloxHwnd)
        return false

    ; Prefer fresh OpenCV detections; fall back to AHK ImageSearch if the worker fails.
    if VisionActive {
        visionResult := VisionFindTemplate(templateName, &visionX, &visionY)
        if visionResult = 1 {
            foundX := visionX
            foundY := visionY
            return true
        }
        if visionResult = 0 || visionResult = -1
            return false
        if visionResult = -2 {
            VisionStop()
            AddLog("OpenCV worker stopped responding; falling back to ImageSearch.")
        }
    }

    file := TemplateDir "\" templateName ".png"
    if !FileExist(file)
        return false

    try {
        WinGetClientPos(&left, &top, &width, &height, "ahk_id " RobloxHwnd)
        if width <= 0 || height <= 0
            return false
        CoordMode("Pixel", "Screen")
        return ImageSearch(&foundX, &foundY, left, top, left + width - 1, top + height - 1, "*" variation " " file)
    } catch {
        return false
    }
}

GetTemplateSize(templateName, &width, &height) {
    global TemplateDir
    width := 0
    height := 0
    if !RegExMatch(templateName, "^[A-Za-z0-9_-]{1,64}$")
        return false

    file := TemplateDir "\" templateName ".png"
    if !FileExist(file)
        return false

    bitmap := 0
    try {
        bitmap := LoadPicture(file)
        if !bitmap
            return false
        bitmapInfo := Buffer(32, 0)
        if !DllCall("gdi32\GetObjectW", "Ptr", bitmap, "Int", bitmapInfo.Size, "Ptr", bitmapInfo)
            return false
        width := NumGet(bitmapInfo, 4, "Int")
        height := NumGet(bitmapInfo, 8, "Int")
        return width > 0 && height > 0
    } catch {
        return false
    } finally {
        if bitmap
            DllCall("gdi32\DeleteObject", "Ptr", bitmap)
    }
}

ClickTemplate(templateName, cooldownKey, cooldownMs := 1500) {
    global ModuleCooldowns
    now := A_TickCount
    if ModuleCooldowns.Has(cooldownKey) && now - ModuleCooldowns[cooldownKey] < cooldownMs
        return false

    if !FindTemplate(templateName, &x, &y)
        return false
    if !GetTemplateSize(templateName, &w, &h)
        return false

    ; Click the center of the matched image rather than an arbitrary +8 offset.
    if InputClickScreen(x + Floor(w / 2), y + Floor(h / 2)) {
        ModuleCooldowns[cooldownKey] := now
        AddLog("Template action: " templateName)
        return true
    }
    return false
}

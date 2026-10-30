#Requires AutoHotkey v2.0
global TemplateDir := A_ScriptDir "\Templates"

FindTemplate(templateName, &foundX := 0, &foundY := 0, variation := 25) {
    global RobloxHwnd, TemplateDir
    foundX := 0, foundY := 0
    if !RobloxHwnd || !WinExist("ahk_id " RobloxHwnd)
        return false
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
ClickTemplate(templateName, cooldownKey, cooldownMs := 1500) {
    global ModuleCooldowns
    now := A_TickCount
    if ModuleCooldowns.Has(cooldownKey) && now - ModuleCooldowns[cooldownKey] < cooldownMs
        return false
    if !FindTemplate(templateName, &x, &y)
        return false
    if InputClickScreen(x + 8, y + 8) {
        ModuleCooldowns[cooldownKey] := now
        AddLog("Template action: " templateName)
        return true
    }
    return false
}

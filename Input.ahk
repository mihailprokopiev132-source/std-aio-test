#Requires AutoHotkey v2.0

InputClickScreen(x, y, button := "Left") {
    global RobloxHwnd
    if !RobloxHwnd || !WinExist("ahk_id " RobloxHwnd) || !WinActive("ahk_id " RobloxHwnd)
        return false
    WinGetClientPos(&left, &top, &width, &height, "ahk_id " RobloxHwnd)
    if x < left || y < top || x >= left + width || y >= top + height
        return false
    Click(x, y, 1, button)
    return true
}
InputClickClient(x, y, button := "Left") {
    global RobloxHwnd
    if !RobloxHwnd || !WinExist("ahk_id " RobloxHwnd)
        return false
    WinGetClientPos(&left, &top, &width, &height, "ahk_id " RobloxHwnd)
    if x < 0 || y < 0 || x >= width || y >= height
        return false
    return InputClickScreen(left + x, top + y, button)
}
InputPressKey(key) {
    global RobloxHwnd
    allowed := ["w","a","s","d","e","q","r","f","space","shift","ctrl","alt","tab","enter","esc","up","down","left","right","1","2","3","4","5"]
    if !RobloxHwnd || !WinExist("ahk_id " RobloxHwnd) || !WinActive("ahk_id " RobloxHwnd)
        return false
    key := StrLower(key)
    for value in allowed
        if value = key {
            Send(RegExMatch(key, "^[1-5]$") ? key : "{" key "}")
            return true
        }
    return false
}

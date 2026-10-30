#Requires AutoHotkey v2.0
AutoSkip_Tick(state) {
    if state != "InMatch"
        return
    if !FindTemplate("skip_available", &availableX, &availableY)
        return
    ClickTemplate("skip_wave", "skip_wave", 2500)
}

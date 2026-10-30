#Requires AutoHotkey v2.0
AutoUpgrade_Tick(state) {
    if state != "InMatch"
        return
    if !FindTemplate("unit_selected", &selectedX, &selectedY)
        return
    if !FindTemplate("upgrade_available", &availableX, &availableY)
        return
    ClickTemplate("upgrade_button", "upgrade_button", 1800)
}

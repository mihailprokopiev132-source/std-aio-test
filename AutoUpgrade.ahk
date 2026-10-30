#Requires AutoHotkey v2.0
AutoUpgrade_Tick() {
    ; Requires user-captured Templates/upgrade_button.png.
    ClickTemplate("upgrade_button", "upgrade_button", 1800)
}

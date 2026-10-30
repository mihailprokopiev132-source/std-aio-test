#Requires AutoHotkey v2.0
AutoFarm_Tick(state) {
    if state != "Lobby"
        return
    ClickTemplate("start_match", "start_match", 8000)
}

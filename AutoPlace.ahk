#Requires AutoHotkey v2.0
global AutoPlaceDone := Map()

AutoPlace_Tick(state) {
    global Settings, AutoPlaceDone
    if state != "InMatch"
        return
    count := Settings["PlacementCount"]
    if count <= 0 || !FindTemplate("placement_ready", &readyX, &readyY)
        return

    Loop count {
        i := A_Index
        key := "placement_" i
        if AutoPlaceDone.Has(key)
            continue
        slot := Settings["PlaceSlot" i]
        x := Settings["PlaceX" i]
        y := Settings["PlaceY" i]
        if x < 0 || y < 0
            continue
        if InputPressKey(slot) {
            Sleep(120)
            if InputClickClient(x, y) {
                AutoPlaceDone[key] := true
                AddLog("AutoPlace: placement " i " executed.")
            }
        }
    }
}

#Requires AutoHotkey v2.0

global ConfigPath := A_ScriptDir "\config.ini"
global Settings := Map()

LoadSettings() {
    global ConfigPath, Settings
    Settings := Map()
    Settings["CaptureInterval"] := Clamp(Integer(IniRead(ConfigPath, "General", "CaptureInterval", "250")), 30, 5000)
    Settings["RecognitionMethod"] := IniRead(ConfigPath, "General", "RecognitionMethod", "ImageSearch")
    Settings["GameMode"] := IniRead(ConfigPath, "General", "GameMode", "Solo")
    Settings["AutoFarm"] := IniRead(ConfigPath, "Modules", "AutoFarm", "1") = "1"
    Settings["AutoUpgrade"] := IniRead(ConfigPath, "Modules", "AutoUpgrade", "1") = "1"
    Settings["AutoSkip"] := IniRead(ConfigPath, "Modules", "AutoSkip", "0") = "1"
    Settings["AutoPlace"] := IniRead(ConfigPath, "Modules", "AutoPlace", "1") = "1"
    Settings["PlacementCount"] := Clamp(Integer(IniRead(ConfigPath, "Placement", "Count", "0")), 0, 20)
    Loop 20 {
        i := A_Index
        Settings["PlaceX" i] := Integer(IniRead(ConfigPath, "Placement", "X" i, "0"))
        Settings["PlaceY" i] := Integer(IniRead(ConfigPath, "Placement", "Y" i, "0"))
        Settings["PlaceSlot" i] := IniRead(ConfigPath, "Placement", "Slot" i, String(Mod(i - 1, 5) + 1))
    }
    return Settings
}

SaveSettingsFromGui() {
    global ConfigPath, Settings
    global IntervalInput, RecognitionSelect, ModeSelect
    global FarmCheck, UpgradeCheck, WaveCheck, AutoPlaceCheck

    interval := Integer(IntervalInput.Value)
    if interval < 30 || interval > 5000
        throw ValueError("Capture interval must be between 30 and 5000 ms.")

    Settings["CaptureInterval"] := interval
    Settings["RecognitionMethod"] := RecognitionSelect.Text
    Settings["GameMode"] := ModeSelect.Text
    Settings["AutoFarm"] := FarmCheck.Value = 1
    Settings["AutoUpgrade"] := UpgradeCheck.Value = 1
    Settings["AutoSkip"] := WaveCheck.Value = 1
    Settings["AutoPlace"] := AutoPlaceCheck.Value = 1

    IniWrite(interval, ConfigPath, "General", "CaptureInterval")
    IniWrite(Settings["RecognitionMethod"], ConfigPath, "General", "RecognitionMethod")
    IniWrite(Settings["GameMode"], ConfigPath, "General", "GameMode")
    IniWrite(Settings["AutoFarm"] ? 1 : 0, ConfigPath, "Modules", "AutoFarm")
    IniWrite(Settings["AutoUpgrade"] ? 1 : 0, ConfigPath, "Modules", "AutoUpgrade")
    IniWrite(Settings["AutoSkip"] ? 1 : 0, ConfigPath, "Modules", "AutoSkip")
    IniWrite(Settings["AutoPlace"] ? 1 : 0, ConfigPath, "Modules", "AutoPlace")
    return true
}

Clamp(value, minimum, maximum) {
    return Max(minimum, Min(maximum, value))
}

#Requires AutoHotkey v2.0

global ConfigPath := A_ScriptDir "\config.ini"
global Settings := Map()

LoadSettings() {
    global ConfigPath, Settings
    Settings := Map()

    Settings["CaptureInterval"] := ReadIniInt("General", "CaptureInterval", 250, 30, 5000)
    method := IniRead(ConfigPath, "General", "RecognitionMethod", "ImageSearch")
    Settings["RecognitionMethod"] := method = "ImageSearch" ? method : "ImageSearch"

    mode := IniRead(ConfigPath, "General", "GameMode", "Solo")
    Settings["GameMode"] := (mode = "Multiplayer") ? mode : "Solo"

    Settings["AutoFarm"] := ReadIniBool("Modules", "AutoFarm", true)
    Settings["AutoUpgrade"] := ReadIniBool("Modules", "AutoUpgrade", true)
    Settings["AutoSkip"] := ReadIniBool("Modules", "AutoSkip", false)
    Settings["AutoPlace"] := ReadIniBool("Modules", "AutoPlace", true)
    Settings["PlacementCount"] := ReadIniInt("Placement", "Count", 0, 0, 20)

    Loop 20 {
        i := A_Index
        Settings["PlaceX" i] := ReadIniInt("Placement", "X" i, 0, 0, 10000)
        Settings["PlaceY" i] := ReadIniInt("Placement", "Y" i, 0, 0, 10000)
        slot := IniRead(ConfigPath, "Placement", "Slot" i, String(Mod(i - 1, 5) + 1))
        Settings["PlaceSlot" i] := RegExMatch(slot, "^[1-5]$") ? slot : String(Mod(i - 1, 5) + 1)
    }
    return Settings
}

ReadIniInt(section, key, fallback, minimum, maximum) {
    global ConfigPath
    try {
        value := Integer(IniRead(ConfigPath, section, key, String(fallback)))
    } catch {
        value := fallback
    }
    return Clamp(value, minimum, maximum)
}

ReadIniBool(section, key, fallback) {
    global ConfigPath
    value := StrLower(IniRead(ConfigPath, section, key, fallback ? "1" : "0"))
    return value = "1" || value = "true" || value = "yes"
}

SaveSettingsFromGui() {
    global ConfigPath, Settings
    global IntervalInput, RecognitionSelect, ModeSelect
    global FarmCheck, UpgradeCheck, WaveCheck, AutoPlaceCheck

    try {
        interval := Integer(IntervalInput.Value)
    } catch {
        throw ValueError("Capture interval must be a whole number.")
    }
    if interval < 30 || interval > 5000
        throw ValueError("Capture interval must be between 30 and 5000 ms.")

    Settings["CaptureInterval"] := interval
    Settings["RecognitionMethod"] := "ImageSearch"
    Settings["GameMode"] := ModeSelect.Text = "Multiplayer" ? "Multiplayer" : "Solo"
    Settings["AutoFarm"] := FarmCheck.Value = 1
    Settings["AutoUpgrade"] := UpgradeCheck.Value = 1
    Settings["AutoSkip"] := WaveCheck.Value = 1
    Settings["AutoPlace"] := AutoPlaceCheck.Value = 1

    IniWrite(interval, ConfigPath, "General", "CaptureInterval")
    IniWrite("ImageSearch", ConfigPath, "General", "RecognitionMethod")
    IniWrite(Settings["GameMode"], ConfigPath, "General", "GameMode")
    IniWrite(Settings["AutoFarm"] ? 1 : 0, ConfigPath, "Modules", "AutoFarm")
    IniWrite(Settings["AutoUpgrade"] ? 1 : 0, ConfigPath, "Modules", "AutoUpgrade")
    IniWrite(Settings["AutoSkip"] ? 1 : 0, ConfigPath, "Modules", "AutoSkip")
    IniWrite(Settings["AutoPlace"] ? 1 : 0, ConfigPath, "Modules", "AutoPlace")

    IniWrite(Settings["PlacementCount"], ConfigPath, "Placement", "Count")
    Loop 20 {
        i := A_Index
        IniWrite(Settings["PlaceX" i], ConfigPath, "Placement", "X" i)
        IniWrite(Settings["PlaceY" i], ConfigPath, "Placement", "Y" i)
        IniWrite(Settings["PlaceSlot" i], ConfigPath, "Placement", "Slot" i)
    }
    return true
}

Clamp(value, minimum, maximum) {
    return Max(minimum, Min(maximum, value))
}

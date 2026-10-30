#Requires AutoHotkey v2.0

global VisionActive := false
global VisionPid := 0
global VisionStartedAt := 0
global VisionOutputPath := A_ScriptDir "\runtime\vision.tsv"
global VisionStopPath := A_ScriptDir "\runtime\vision.stop"

VisionStart() {
    global VisionActive, VisionPid, VisionStartedAt
    global VisionOutputPath, VisionStopPath

    if VisionActive
        return true

    try {
        DirCreate(A_ScriptDir "\runtime")
        if FileExist(VisionStopPath)
            FileDelete(VisionStopPath)
        if FileExist(VisionOutputPath)
            FileDelete(VisionOutputPath)

        worker := A_ScriptDir "\vision\vision_worker.py"
        if !FileExist(worker) {
            AddLog("OpenCV worker not found; using built-in ImageSearch.")
            return false
        }

        command := 'pythonw.exe "' worker '"'
            . ' --templates "' A_ScriptDir '\Templates"'
            . ' --output "' VisionOutputPath '"'
            . ' --stop-file "' VisionStopPath '"'
            . ' --fps 8 --threshold 0.82'

        Run(command, A_ScriptDir, "Hide", &VisionPid)
        VisionStartedAt := A_TickCount
        VisionActive := true
        AddLog("OpenCV vision worker launched.")
        return true
    } catch as err {
        VisionActive := false
        VisionPid := 0
        AddLog("OpenCV worker unavailable; using ImageSearch. " err.Message)
        return false
    }
}

VisionStop() {
    global VisionActive, VisionPid, VisionStopPath
    if !VisionActive
        return
    try {
        DirCreate(A_ScriptDir "\runtime")
        FileAppend("stop", VisionStopPath, "UTF-8")
    } catch as err {
        AddLog("Could not signal OpenCV worker to stop: " err.Message)
    }
    VisionActive := false
    VisionPid := 0
}

; Return values: 1 = found, 0 = fresh frame but no match, -1 = worker starting,
; -2 = worker failed/stale. Coordinates returned are screen coordinates.
VisionFindTemplate(templateName, &foundX, &foundY) {
    global VisionActive, VisionStartedAt, VisionOutputPath
    foundX := 0
    foundY := 0
    if !VisionActive
        return -2

    if !FileExist(VisionOutputPath) {
        if A_TickCount - VisionStartedAt < 5000
            return -1
        return -2
    }

    try {
        modified := FileGetTime(VisionOutputPath, "M")
    } catch {
        return -1
    }
    if DateDiff(A_Now, modified, "Seconds") > 3
        return -2
    try {
        content := FileRead(VisionOutputPath, "UTF-8")
    } catch {
        ; A frame may be atomically replaced while the reader opens it.
        return -1
    }

    lines := StrSplit(content, "`n", "`r")
    if lines.Length < 2
        return -2

    frame := StrSplit(lines[1], "`t")
    status := StrSplit(lines[2], "`t")
    if frame.Length < 6 || frame[1] != "FRAME" || status.Length < 2
        return -2
    if status[2] != "OK" && status[2] != "NO_TEMPLATES"
        return -2

    for line in lines {
        fields := StrSplit(line, "`t")
        if fields.Length < 7 || fields[1] != "HIT" || fields[2] != templateName
            continue
        foundX := Integer(frame[3]) + Integer(fields[3])
        foundY := Integer(frame[4]) + Integer(fields[4])
        return 1
    }
    return 0
}

// Criação de log específico da api de DFes

procedure apiLog(log)
    local path := appData:systemPath + 'log\'
    local dateFormat := Set(_SET_DATEFORMAT, "yyyy.mm.dd")
    local logFile := 'apiLog' + hb_ULeft(DToS(Date()),6) + '.json'
    local hLog := {=>}, process := ""

    if !Empty(ProcName(3))
        process := ProcName(3) + '(' + hb_ntos(ProcLine(3)) + ')/'
    endif
    if !Empty(ProcName(2))
        process += ProcName(2) + '(' + hb_ntos(ProcLine(2)) + ')/'
    endif

    process += ProcName(1) + '(' + hb_ntos(ProcLine(1)) + ')'

    log["version"] := appData:displayName
    log["date"] := DtoC(Date()) + ' ' + Time()
    log["trace"] := process

    if hb_FileExists(path + logFile)
        hLog := hb_jsonDecode(hb_MemoRead(path + logFile))
    else
        hLog["name"] := "Log de Sistema " + appData:displayName + " | " + Upper(GetMonthName(Month(Date()))) + " DE " + hb_ntos(Year(Date()))
        hLog["log"] := {}
    endif

    AAdd(hLog["log"], log)
    hb_MemoWrit(path + logFile, hb_jsonEncode(hLog, 4))
    Set(_SET_DATEFORMAT, dateFormat)

return
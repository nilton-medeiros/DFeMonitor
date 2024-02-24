// Criação de log específico da api de DFes

procedure apiLog(log)
    local path := appData:systemPath + 'log\'
    local dateFormat := Set(_SET_DATEFORMAT, "yyyy.mm.dd")
    local logFile := 'apiLog' + hb_ULeft(DToS(Date()),6) + '.json'
    local hLog := {=>}, logSorted := {=>}, process := "", jsonString

    if !Empty(ProcName(3))
        process := ProcName(3) + '(' + hb_ntos(ProcLine(3)) + ')/'
    endif
    if !Empty(ProcName(2))
        process += ProcName(2) + '(' + hb_ntos(ProcLine(2)) + ')/'
    endif

    process += ProcName(1) + '(' + hb_ntos(ProcLine(1)) + ')'

    logSorted["version"] := appData:displayName
    logSorted["date"] := DtoC(Date()) + ' ' + Time()
    logSorted["type"] := log["type"]
    logSorted["trace"] := process
    logSorted["method"] := log["method"]
    logSorted["url"] := log["url"]
    logSorted["content_type"] := log["content_type"]
    logSorted["accept"] := log["accept"]
    logSorted["description"] := log["description"]
    logSorted["response"] := log["response"]
    logSorted["body"] := log["body"]
    if hb_FileExists(path + logFile)
        hLog := hb_jsonDecode(hb_MemoRead(path + logFile))
    else
        hLog["name"] := "Log de Sistema " + appData:displayName + " | " + Upper(GetMonthName(Month(Date()))) + " DE " + hb_ntos(Year(Date()))
        hLog["log"] := {}
    endif

    AAdd(hLog["log"], logSorted)

    jsonString := hb_jsonEncode(hLog, 4)
    jsonString := StrTran(jsonString, '"$$')
    jsonString := StrTran(jsonString, '$$"')

    hb_MemoWrit(path + logFile, jsonString)
    Set(_SET_DATEFORMAT, dateFormat)

    log := nil
    hLog := nil
    logSorted := nil
    
return
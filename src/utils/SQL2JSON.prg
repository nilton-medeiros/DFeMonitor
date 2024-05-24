procedure saveSQL(sql)
    local fileJson := appData:systemPath + 'log\recovery_sql.json'
    hb_MemoWrit(fileJson, hb_jsonEncode({"sql" => sql}, 4))
return

procedure recoverySQL()
    local fileJson := appData:systemPath + 'log\recovery_sql.json'
    local hSQL, q

    if hb_FileExists(fileJson)
        hSQL := hb_jsonDecode(hb_MemoRead(fileJson))
        hb_FileDelete(fileJson)
        if hb_HGetRef(hSQL, "sql")
            q := TQuery():new(hSQL["sql"])
            if !q:executed
                saveLog({"DB: Erro ao executar o SQL recuperado", hSQL["sql"]}, "Debug")
            endif
            q:Destroy()
        endif
    endif

return 
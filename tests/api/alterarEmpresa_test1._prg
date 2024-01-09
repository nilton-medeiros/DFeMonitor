procedure testAlterarEmpresa()
    local msgLog, empresa := appEmpresas:empresas[1]
    local apiEmpresa := TApiEmpresas():new(empresa)

    msgLog := "INTEGRAÇÃO COM NUVEM FISCAL: TESTANDO ALTERAR EMPRESA EMITENTE" + hb_eol() + hb_eol()
    msgLog += ">> ESPERA-SE SUCESSO AO ALTERAR O COMPLEMENTO DO ENDEREÇO <<" + hb_eol() + hb_eol()
    consoleLog(msgLog)

    empresa:xCpl := "Complemento teste"

    if apiEmpresa:connected
        if apiEmpresa:Alterar()
            MsgBox("Empresa alterada com sucesso!", "DFeMonitor " + appData:version + " - API Nuvem Fiscal")
            consoleLog("Empresa alterada com sucesso!")
        else
            MsgExclamation("Falha ao alterar empresa, ver consoleLog", "DFeMonitor " + appData:version + " - API Nuvem Fiscal")
            consoleLog("Falha ao alterar empresa!")
        endif
    else
        MsgExclamation("Falha de conexão com a Nuvem Fiscal, ver consoleLog", "DFeMonitor " + appData:version + " - API Nuvem Fiscal")
    endif

return
procedure testCadastrarEmpresa()
    local msgLog, empresa := appEmpresas:empresas[1]
    local apiEmpresa := TApiEmpresas():new(empresa)

    msgLog := "INTEGRAÇÃO COM NUVEM FISCAL: TESTANDO CADASTRAR EMPRESA EMITENTE" + hb_eol() + hb_eol()
    msgLog += ">> ESPERA-SE CONEXÃO OK MAS FALHE O CADASTRO POR CAMPOS INVÁLIDOS <<" + hb_eol() + hb_eol()
    consoleLog(msgLog)

    empresa:CNPJ := "0000000000" // 10 zeros, DEVERÁ RETORNAR ERRO NO CNPJ

    if apiEmpresa:connected
        if apiEmpresa:Cadastrar()
            MsgBox("Empresa cadastrada com sucesso!", "DFeMonitor " + appData:version + " - API Nuvem Fiscal")
            consoleLog("Empresa cadastrada com sucesso!")
        else
            MsgExclamation("Falha ao cadastrar empresa, ver consoleLog", "DFeMonitor " + appData:version + " - API Nuvem Fiscal")
            consoleLog("Falha ao cadastrar empresa!")
        endif
    else
        MsgExclamation("Falha de conexão com a Nuvem Fiscal, ver consoleLog", "DFeMonitor " + appData:version + " - API Nuvem Fiscal")
    endif

return
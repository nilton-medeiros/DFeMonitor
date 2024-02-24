
procedure cadastrarEmpresa(empresa)
    local apiEmpresa := TApiEmpresas():new(empresa)

    if apiEmpresa:connected
        if apiEmpresa:Cadastrar()
            saveLog("Empresa " + empresa:CNPJ + "cadastrada na API Nuvem Fiscal com sucesso!")
        else
            saveLog({"Falha ao cadastrar empresa na API Nuvem Fiscal",;
                "Content-Type: " + apiEmpresa:ContentType,;
                "Response: " + apiEmpresa:response,;
                "Html Status: " + hb_ntos(apiEmpresa:responseStatus)}, "Error")
        endif
    else
        saveLog("Falha de conexão com API Nuvem Fiscal!", "Error")
    endif

return

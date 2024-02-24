
procedure alterarEmpresa(empresa)
    local apiEmpresa := TApiEmpresas():new(empresa)

    if apiEmpresa:connected
        if apiEmpresa:Alterar()
            saveLog("Empresa " + empresa:CNPJ + " alterada na API Nuvem Fiscal com sucesso!")
            empresa:update()
        else
            saveLog({"Falha ao alterar empresa na API Nuvem Fiscal",;
                "Content-Type: " + apiEmpresa:ContentType,;
                "Response: " + apiEmpresa:response,;
                "HTTP Status: " + hb_ntos(apiEmpresa:responseStatus)}, "Error")
        endif
    else
        saveLog("Falha de conexão com API Nuvem Fiscal!", "Error")
    endif

return

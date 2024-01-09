
procedure alterarEmpresa(empresa)
    local apiEmpresa := TApiEmpresas():new(empresa)

    if apiEmpresa:connected
        if apiEmpresa:Alterar()
            saveLog("Empresa " + empresa:CNPJ + " alterada na API Nuvem Fiscal com sucesso!")
            empresa:update()
        else
            saveLog("Falha ao alterar empresa na API Nuvem Fiscal")
            saveLog({;
                "Content-Type: " + apiEmpresa:ContentType, hb_eol(),;
                "Response: " + apiEmpresa:response, hb_eol(),;
                "Html Status: " + hb_ntos(apiEmpresa:responseStatus);
            })
        endif
    else
        saveLog("Falha de conexão com API Nuvem Fiscal!")
    endif

return

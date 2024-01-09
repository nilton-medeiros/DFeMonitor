
procedure cadastrarEmpresa(empresa)
    local apiEmpresa := TApiEmpresas():new(empresa)

    if apiEmpresa:connected
        if apiEmpresa:Cadastrar()
            saveLog("Empresa " + empresa:CNPJ + "cadastrada na API Nuvem Fiscal com sucesso!")
        else
            saveLog("Falha ao cadastrar empresa na API Nuvem Fiscal")
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

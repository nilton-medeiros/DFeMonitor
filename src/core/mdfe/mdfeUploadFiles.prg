#define false .F.
#define true .T.

procedure mdfeUploadFiles(upload)
    local mdfe := upload["mdfe"], empresa := upload["empresa"]
    local upFTP, remotePath := empresa:remote_file_path + "/mdf/files"

    if hb_HGetRef(upload, "pdf")
        upFTP := TGED_FTP():new(upload["pdf"], remotePath)
        if upFTP:upload()
            mdfe:setUpdateMdfe('pdf', upFTP:getURL())
            hEvent := {=>}
            hEvent["evento"] := "PDF"
            hEvent["status_evento"] := "UPLOAD PDF"
            hEvent["data_evento"] := date_as_DateTime(date(), false, false)
            hEvent["data_hora"] := date_as_DateTime(date(), false, false)
            hEvent["motivo_status"] := "Arquivo PDF do DAMDFE carregado com sucesso!"
            mdfe:setUpdateEventos(hEvent)
        else
            hEvent := {=>}
            hEvent["evento"] := "PDF"
            hEvent["status_evento"] := "erro"
            hEvent["data_evento"] := date_as_DateTime(date(), false, false)
            hEvent["data_hora"] := date_as_DateTime(date(), false, false)
            hEvent["motivo_status"] := "Falha ao carregar Arquivo PDF do DAMDFE, ver log servidor local!"
            mdfe:setUpdateEventos(hEvent)
        endif
    endif

    if hb_HGetRef(upload, "xml")
        upFTP := TGED_FTP():new(upload["xml"], remotePath)
        if upFTP:upload()
            mdfe:setUpdateMdfe('xml', upFTP:getURL())
            hEvent := {=>}
            hEvent["evento"] := "XML"
            hEvent["data_evento"] := date_as_DateTime(date(), false, false)
            hEvent["data_hora"] := date_as_DateTime(date(), false, false)
            hEvent["motivo_status"] := "Arquivo XML do MDFe carregado com sucesso!"
            mdfe:setUpdateEventos(hEvent)
        else
            hEvent := {=>}
            hEvent["evento"] := "XML"
            hEvent["status_evento"] := "erro"
            hEvent["data_evento"] := date_as_DateTime(date(), false, false)
            hEvent["data_hora"] := date_as_DateTime(date(), false, false)
            hEvent["motivo_status"] := "Falha ao carregar Arquivo XML do MDFe, ver log servidor local!"
            mdfe:setUpdateEventos(hEvent)
        endif
    endif

return
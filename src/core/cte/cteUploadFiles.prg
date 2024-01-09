#define false .F.
#define true .T. 

procedure cteUploadFiles(upload)
    local cte := upload["cte"], empresa := upload["empresa"]
    local upFTP, remotePath := empresa:remote_file_path + "/ctes/files"

    if hb_HGetRef(upload, "pdf")
        upFTP := TGED_FTP():new(upload["pdf"], remotePath)
        if upFTP:upload()
            cte:setUpdateCte('cte_pdf', upFTP:getURL())
            cte:setUpdateEventos("UPLOAD PDF", date_as_DateTime(date(), false, false), "FILE PDF", "Arquivo PDF do DACTE carregado com sucesso!")
        else
            cte:setUpdateEventos("UPLOAD PDF", date_as_DateTime(date(), false, false), "FILE PDF", "Falha ao carregar Arquivo PDF do DACTE, ver log servidor local!")
        endif
    endif

    if hb_HGetRef(upload, "xml")
        upFTP := TGED_FTP():new(upload["xml"], remotePath)
        if upFTP:upload()
            cte:setUpdateCte('cte_xml', upFTP:getURL())
            cte:setUpdateEventos("UPLOAD XML", date_as_DateTime(date(), false, false), "FILE XML", "Arquivo XML do CTE carregado com sucesso!")
        else
            cte:setUpdateEventos("UPLOAD XML", date_as_DateTime(date(), false, false), "FILE XML", "Falha ao carregar Arquivo XML do CTE, ver log servidor local!")
        endif
    endif

    if hb_HGetRef(upload, "pdfCancel")
        upFTP := TGED_FTP():new(upload["pdfCancel"], remotePath)
        if upFTP:upload()
            cte:setUpdateCte('cte_cancelado_pdf', upFTP:getURL())
            cte:setUpdateEventos("UPLOAD PDF", date_as_DateTime(date(), false, false), "FILE PDF", "Arquivo PDF do CTE CANCELADO carregado com sucesso!")
        else
            cte:setUpdateEventos("UPLOAD PDF", date_as_DateTime(date(), false, false), "FILE PDF", "Falha ao carregar Arquivo PDF do CTE CANCELADO, ver log servidor local!")
        endif
    endif

    if hb_HGetRef(upload, "xmlCancel")
        upFTP := TGED_FTP():new(upload["xmlCancel"], remotePath)
        if upFTP:upload()
            cte:setUpdateCte('cte_cancelado_xml', upFTP:getURL())
            cte:setUpdateEventos("UPLOAD XML", date_as_DateTime(date(), false, false), "FILE XML", "Arquivo XML do CTE CANCELADO carregado com sucesso!")
        else
            cte:setUpdateEventos("UPLOAD XML", date_as_DateTime(date(), false, false), "FILE XML", "Falha ao carregar Arquivo XML do CTE CANCELADO, ver log servidor local!")
        endif
    endif

return
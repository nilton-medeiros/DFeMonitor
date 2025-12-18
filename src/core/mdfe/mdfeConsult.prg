#include "hmg.ch"

procedure mdfeConsult(mdfe)
    local apiMDFe := TApiMDFe():new(mdfe)
    local aError, error, lError := false

    /*
        Se está fazendo uma consulta, é porque houve algum tipo de erro ao emitir, cancelar ou gerar PDF/XML,
        nesse caso, solicita uma Sincronização entre SEFAZ e NUVEM FISCAL antes de consultar.
    */

    if apiMDFe:Sincronizar()
        if apiMDFe:ListarMDFes()
            // Prepara os campos da tabela mdfes para receber os updates
            mdfe:setSituacao(apiMDFe:status)
            mdfe:setUpdateMDFe('cMDF', apiMDFe:chave)
            mdfe:setUpdateMDFe('digest_value', apiMDFe:digest_value)
            mdfe:setUpdateMDFe('nProt', apiMDFe:numero_protocolo)
            mdfe:setUpdateMDFe('nuvemfiscal_uuid', apiMDFe:nuvemfiscal_uuid)
            // Prepara os campos da tabela mdfes_eventos para receber os updates
            if !Empty(apiMDFe:hEvent)
                mdfe:setUpdateEventos(apiMDFe:hEvent)
            endif
            if Lower(apiMDFe:status) $ "autorizado|encerrado|cancelado"
                mdfeGetFiles(apiMDFe)
            endif
        else
            saveLog({"Erro ao consultar MDFe", "Referência: " + mdfe:referencia_uuid}, "Warning")
            lError := true
        endif
    else
        saveLog({"Erro na sincronização do MDFe", "Referência: " + mdfe:referencia_uuid}, "Warning")
        lError := true
    endif

    if lError
        aError := getMessageApiError(apiMDFe, false)
        for each error in aError
            hEvent := {=>}
            hEvent["codigo_status"] := error["code"]
            hEvent["status_evento"] := "erro"
            hEvent["data_evento"] := date_as_DateTime(date(), false, false)
            hEvent["data_hora"] := date_as_DateTime(date(), false, false)
            hEvent["motivo_status"] := error["message"]
            mdfe:setUpdateEventos(hEvent)
        next
        mdfe:setSituacao("ERRO")
    endif

return
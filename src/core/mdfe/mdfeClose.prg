#include "hmg.ch"

procedure mdfeClose(mdfe)
    local apiMDFe := TApiMDFe():new(mdfe)
    local aError, error, hEvent

    if apiMDFe:Encerrar()
        if (apiMDFe:codigo_status == 135)
            mdfe:setSituacao("ENCERRADO")
            mdfeGetFiles(apiMDFe)
        else
            mdfe:setSituacao(apiMDFe:status)
            saveLog({"Evento de Encerramento Registrado", "apiMDFe:status " + apiMDFe:status, "cStat: " + hb_ntos(piMDFe:codigo_status)})
        endif

        // Prepara os campos da tabela mdfes_eventos para receber os updates
        if !Empty(apiMDFe:hEvent)
            mdfe:setUpdateEventos(apiMDFe:hEvent)
        endif

    else
        aError := getMessageApiError(apiMDFe, false)
        for each error in aError
            hEvent := {=>}
            hEvent["motivo"] := error["code"]
            hEvent["detalhe"] := error["message"]
            hEvent["data_evento"] := date_as_DateTime(date(), false, false)
            hEvent["data_hora"] := date_as_DateTime(date(), false, false)
            mdfe:setUpdateEventos(hEvent)
        next
        mdfe:setSituacao(apiMDFe:status)
        apiLog({"type" => "Warning", "description" => "Erro ao encerrar MDFe", "response" => apiMDFe:response})
    endif

return

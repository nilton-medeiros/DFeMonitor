#include "hmg.ch"

procedure mdfeCancel(mdfe)
    local apiMDFe := TApiMDFe():new(mdfe)
    local aError, error, hEvent

    if apiMDFe:Cancelar()

        // Prepara os campos da tabela mdfes para receber os updates
        if (apiMDFe:codigo_status == 135)
            mdfe:setSituacao("CANCELADO")
            mdfeGetFiles(apiMDFe)
        else
            mdfe:setSituacao(apiMDFe:status)
            saveLog({"Evento de Cancelamento Registrado", "apiMDFe:status " + apiMDFe:status, "cStat: " + hb_ntos(apiMDFe:codigo_status)})
        endif

        // Prepara os campos da tabela mdfes_eventos para receber os updates
        if !Empty(apiMDFe:motivo_status)
            mdfe:setUpdateEventos(apiMDFe:hEvent)
            if !Empty(apiMDFe:tipo_evento)
                mdfe:setUpdateEventos(apiMDFe:hEvent)
            endif
        endif
        if !Empty(apiMDFe:mensagem)
            mdfe:setUpdateEventos(apiMDFe:hEvent)
            if !Empty(apiMDFe:tipo_evento)
                mdfe:setUpdateEventos(apiMDFe:hEvent)
            endif
        endif

    else
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
        mdfe:setSituacao(apiMDFe:status)
        apiLog({"type" => "Warning", "description" => "Erro ao cancelar: MDFe", "response" => apiMDFe:response})
    endif

return

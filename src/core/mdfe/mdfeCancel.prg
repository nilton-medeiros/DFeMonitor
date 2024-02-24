#include "hmg.ch"

procedure mdfeCancel(mdfe)
    local apiMDFe := TApiMDFe():new(mdfe)
    local aError, error

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
            mdfe:setUpdateEventos(apiMDFe:numero_protocolo, apiMDFe:data_evento, apiMDFe:codigo_status, apiMDFe:motivo_status)
            if !Empty(apiMDFe:tipo_evento)
                mdfe:setUpdateEventos(apiMDFe:numero_protocolo, apiMDFe:data_evento, apiMDFe:codigo_status, "Tipo Evento: " + apiMDFe:tipo_evento)
            endif
        endif
        if !Empty(apiMDFe:mensagem)
            mdfe:setUpdateEventos(apiMDFe:numero_protocolo, apiMDFe:data_recebimento, apiMDFe:codigo_status, apiMDFe:mensagem)
            if !Empty(apiMDFe:tipo_evento)
                mdfe:setUpdateEventos(apiMDFe:numero_protocolo, apiMDFe:data_recebimento, apiMDFe:codigo_status, "Tipo Evento: " + apiMDFe:tipo_evento)
            endif
        endif

    else
        aError := getMessageApiError(apiMDFe, false)
        for each error in aError
            mdfe:setUpdateEventos("Erro", date_as_DateTime(date(), false, false), error["code"], error["message"])
        next
        mdfe:setSituacao(apiMDFe:status)
        apiLog({"type" => "Warning", "description" => "Erro ao cancelar: MDFe", "response" => apiMDFe:response})
    endif

return

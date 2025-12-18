#include "hmg.ch"

procedure mdfeSubmit(mdfe)
    local svrs, apiMDFe := TApiMDFe():new(mdfe)
    local aError, error, hEvent

    // Refatorado, na versão CTe 4.00 e MDFe 3.00 a transmissão é sincrono, já é retornado a autorização ou rejeição

    if appData:mdfe_sefaz_offline
        // Verifica se SVRS voltou a ficar disponível (online)
        svrs := apiMDFe:ConsultarSVRS()
        if (svrs["codigo_status"] == 107)
            // SVRS voltou a ficar disponível
            appData:mdfe_sefaz_offline := false
        elseif (svrs["codigo_status"] == -1)
            mdfe:setUpdateEventos(apiMDFe:hEvent)
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
            return
        else
            hEvent := {=>}
            hEvent["protocolo"] := apiMDFe:numero_protocolo
            hEvent["numero_protocolo"] := apiMDFe:numero_protocolo
            hEvent["status_evento"] := "erro"
            hEvent["data_evento"] := apiMDFe:data_evento
            hEvent["data_hora"] := apiMDFe:data_evento
            hEvent["evento"] := "SVRS"
            hEvent["motivo_status"] := "SEFAZ MDFe:RS INDISPONÍVEL, TENTE MAIS TARDE!"
            mdfe:setUpdateEventos(hEvent)
            mdfe:setSituacao("ERRO")
            return
        endif
    endif

    if apiMDFe:Emitir()

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

        if (apiMDFe:codigo_status == 100)
            mdfeGetFiles(apiMDFe)
        endif

    elseif appData:mdfe_sefaz_offline
        hEvent := {=>}
        hEvent["protocolo"] := apiMDFe:numero_protocolo
        hEvent["numero_protocolo"] := apiMDFe:numero_protocolo
        hEvent["status_evento"] := "erro"
        hEvent["data_evento"] := apiMDFe:data_evento
        hEvent["data_hora"] := apiMDFe:data_evento
        hEvent["evento"] := "SVRS"
        hEvent["motivo_status"] := "SEFAZ MDFe:RS INDISPONÍVEL, TENTE MAIS TARDE!"
        mdfe:setUpdateEventos(hEvent)
        mdfe:setSituacao("ERRO")
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
        mdfe:setSituacao("ERRO")

    endif

return

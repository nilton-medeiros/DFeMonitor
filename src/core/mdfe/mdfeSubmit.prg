#include "hmg.ch"

procedure mdfeSubmit(mdfe)
    local svrs, apiMDFe := TApiMDFe():new(mdfe)
    local aError, error

    // Refatorado, na versão CTe 4.00 e MDFe 3.00 a transmissão é sincrono, já é retornado a autorização ou rejeição

    if appData:mdfe_sefaz_offline
        // Verifica se SVRS voltou a ficar disponível (online)
        svrs := apiMDFe:ConsultarSVRS()
        if (svrs["codigo_status"] == 107)
            // SVRS voltou a ficar disponível
            appData:mdfe_sefaz_offline := false
        elseif (svrs["codigo_status"] == -1)
            mdfe:setUpdateEventos(apiMDFe:numero_protocolo, apiMDFe:data_recebimento, apiMDFe:codigo_mensagem, apiMDFe:mensagem)
            aError := getMessageApiError(apiMDFe, false)
            for each error in aError
                mdfe:setUpdateEventos("Erro", date_as_DateTime(date(), false, false), error["code"], error["message"])
            next
            mdfe:setSituacao("ERRO")
            return
        else
            mdfe:setUpdateEventos(apiMDFe:numero_protocolo, apiMDFe:data_evento, "SVRS", "SEFAZ MDFe:RS INDISPONÍVEL, TENTE MAIS TARDE!")
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
        if !Empty(apiMDFe:motivo_status)
            mdfe:setUpdateEventos(apiMDFe:numero_protocolo, apiMDFe:data_evento, apiMDFe:codigo_status, apiMDFe:motivo_status)
        endif
        if !Empty(apiMDFe:mensagem)
            mdfe:setUpdateEventos(apiMDFe:numero_protocolo, apiMDFe:data_recebimento, apiMDFe:codigo_mensagem, apiMDFe:mensagem)
        endif

        if (apiMDFe:codigo_status == 100)
            mdfeGetFiles(apiMDFe)
        endif

    elseif appData:mdfe_sefaz_offline
        mdfe:setUpdateEventos(apiMDFe:numero_protocolo, apiMDFe:data_evento, "SVRS", "SEFAZ MDFe:RS INDISPONÍVEL, TENTE MAIS TARDE!")
        mdfe:setSituacao("ERRO")
    else

        aError := getMessageApiError(apiMDFe, false)
        for each error in aError
            mdfe:setUpdateEventos("Erro", date_as_DateTime(date(), false, false), error["code"], error["message"])
        next
        mdfe:setSituacao("ERRO")

    endif

return

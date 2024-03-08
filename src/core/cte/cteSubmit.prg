#include "hmg.ch"

procedure cteSubmit(cte)
    local sefaz, apiCTe := TApiCTe():new(cte)

    // Refatorado, na versão CTe 4.00 a transmissão é sincrono, já é retornado a autorização ou rejeição

    if appData:cte_sefaz_offline

        // Verifica se a Sefaz SP voltou a ficar disponível (online)
        apiCTe:contingencia := false
        sefaz := apiCTe:ConsultarSefaz()

        if (sefaz["codigo_status"] == 107)
            // Sefaz SP voltou a fica disponível, sai do módo contingência
            appData:cte_sefaz_offline := false
        elseif (sefaz["codigo_status"] == -1)
            cte:setUpdateEventos(apiCTe:numero_protocolo, apiCTe:data_evento, apiCTe:status, apiCTe:mensagem)
            errEmissao(apiCTe, cte)
            return
        else

            // Verifica se a Sefaz Virtual de Contingência (SVC-RS) do RS está disponível (online)
            apiCTe:contingencia := true
            sefaz := apiCTe:ConsultarSefaz()

            if (sefaz["codigo_status"] == -1)
                cte:setUpdateEventos(apiCTe:numero_protocolo, apiCTe:data_evento, apiCTe:status, apiCTe:mensagem)
                errEmissao(apiCTe, cte)
                apiCTe:contingencia := false
                return
            elseif !(sefaz["codigo_status"] == 107)
                // Sefaz SP OFFLINE e SVC-RS ainda não está disponível!
                apiCTe:contingencia := false
                cte:setUpdateEventos(apiCTe:numero_protocolo, apiCTe:data_evento, apiCTe:codigo_status, apiCTe:motivo_status)
                cte:setUpdateEventos(apiCTe:numero_protocolo, apiCTe:data_evento, apiCTe:codigo_status, "SEFAZ SP E SEFAZ RS VIRUTAL DE CONTINGENCIA INDISPONIVEIS!")
                errEmissao(apiCTe, cte)
                return
            else
                // Sefaz Virtual RS em Operação
                // tpEmis: 1 - Normal; 5 - Contingência FSDA; 7 - Autorização pela SVC-RS; 8 - Autorização pela SVC-SP
                cte:tpEmis := 7     // SVC-RS
                cte:dhCont := apiCTe:data_emissao
                cte:xJust := apiCTe:motivo_status
                cte:setUpdateEventos(apiCTe:numero_protocolo, apiCTe:data_evento, apiCTe:codigo_status, apiCTe:motivo_status)
            endif

        endif

    endif

    if apiCTe:Emitir()
        if apiCTe:contingencia
            cte:setUpdateCte("cte_forma_emissao", 7)
            cte:setUpdateCte("cte_obs_gerais", iif(Empty(cte:xObs), "", cte:xObs + " | ") + "EMISSAO EM CONTINGENCIA: SVC-RS")
            cte:setUpdateEventos(apiCTe:numero_protocolo, apiCTe:data_evento, apiCTe:codigo_status, "SEFAZ SP INDISPONIVEL, EMISSAO EM CONTINGENCIA PELA SVC-RS")
            cte:setUpdateEventos(apiCTe:numero_protocolo, apiCTe:data_evento, apiCTe:codigo_status, apiCTe:motivo_status)
        endif
        posEmissao(apiCTe)
        return
    else
        posEmissao(apiCTe)
    endif

    // Não emitiu, Sefaz SP está indisponível, verifica se a Sefaz Virtual RS já está disponível
    if appData:cte_sefaz_offline .and. !apiCTe:contingencia

        cte:setUpdateEventos(apiCTe:numero_protocolo, apiCTe:data_evento, apiCTe:codigo_status, apiCTe:motivo_status)
        cte:setUpdateEventos(apiCTe:numero_protocolo, apiCTe:data_evento, apiCTe:codigo_status, "Verificando ambiente de contigência SVC-RS (Sefaz Virtual de Contingencia do RS)")

        // Em contingência. Consulta a SVC-RS
        apiCTe:contingencia := true
        sefaz := apiCTe:ConsultarSefaz()

        if (sefaz["codigo_status"] == 107)

            // Sefaz Virtual RS em Operação
            // tpEmis: 1 - Normal; 5 - Contingência FSDA; 7 - Autorização pela SVC-RS; 8 - Autorização pela SVC-SP
            cte:tpEmis := 7     // SVC-RS
            cte:dhCont := apiCTe:data_emissao
            cte:xJust := apiCTe:motivo_status

            if apiCTe:Emitir()
                cte:setUpdateCte("cte_forma_emissao", 7)
                cte:setUpdateCte("cte_obs_gerais", iif(Empty(cte:xObs), "", cte:xObs + " | ") + "EMISSAO EM CONTINGENCIA: SVC-RS")
                cte:setUpdateEventos(apiCTe:numero_protocolo, apiCTe:data_evento, apiCTe:codigo_status, "SEFAZ SP INDISPONIVEL, EMISSAO EM CONTINGENCIA PELA SVC-RS")
                cte:setUpdateEventos(apiCTe:numero_protocolo, apiCTe:data_evento, apiCTe:codigo_status, apiCTe:motivo_status)
                posEmissao(apiCTe)
                return
            endif

        elseif (sefaz["codigo_status"] == -1)
            cte:setUpdateEventos(apiCTe:numero_protocolo, apiCTe:data_evento, apiCTe:status, apiCTe:mensagem)
        else
            // Sefaz SP OFFLINE e SVC-RS ainda não está disponível!
            apiCTe:contingencia := false
            cte:setUpdateEventos(apiCTe:numero_protocolo, apiCTe:data_evento, apiCTe:codigo_status, apiCTe:motivo_status)
            cte:setUpdateEventos(apiCTe:numero_protocolo, apiCTe:data_evento, apiCTe:codigo_status, "SEFAZ SP E SEFAZ VIRUTAL DE CONTINGENCIA RS INDISPONIVEIS!")
        endif

    endif

    if Lower(apiCTe:status) == 'erro'
        errEmissao(apiCTe, cte)
    endif

return

procedure posEmissao(api)
    local cDate

    // Prepara os campos da tabela ctes para receber os updates
    api:cte:setSituacao(api:status)
    api:cte:setUpdateCte('cte_chave', api:chave)
    api:cte:setUpdateCte('digest_value', api:digest_value)
    api:cte:setUpdateCte('cte_protocolo_autorizacao', api:numero_protocolo)
    api:cte:setUpdateCte('nuvemfiscal_uuid', api:nuvemfiscal_uuid)

    // Prepara os campos da tabela ctes_eventos para receber os updates
    if !Empty(api:motivo_status)
        api:cte:setUpdateEventos(api:numero_protocolo, api:data_evento, api:codigo_status, api:motivo_status)
    endif
    if !Empty(api:mensagem)
        cDate := api:data_recebimento
        if Empty(cDate)
            cDate := api:data_evento
            if Empty(cDate)
                cDate := date_as_DateTime(date(), false, false)
            endif
        endif
        api:cte:setUpdateEventos(api:numero_protocolo, cDate, api:codigo_status, api:mensagem)
    endif

    if (api:codigo_status == 100) .and. (Lower(api:status) == "autorizado")
        cteGetFiles(api)
    endif

return

procedure errEmissao(apiCTe, cte)
    local error, aError := getMessageApiError(apiCTe, false)
    for each error in aError
        cte:setUpdateEventos("Erro", date_as_DateTime(date(), false, false), error["code"], error["message"])
    next
    cte:setSituacao("ERRO")
return
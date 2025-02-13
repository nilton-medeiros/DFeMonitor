#include "hmg.ch"
#include <hbclass.ch>

class TApiCTe
    data cte readonly
    data emitente readonly
    data token
    data connection
    data connecHttp
    data connected readonly
    data body readonly
    data response readonly
    data httpStatus readonly
    data ContentType readonly
    data nuvemfiscal_uuid
    data referencia_uuid readonly
    data ambiente readonly
    data autorizador readonly
    data created_at readonly
    data data_emissao readonly
    data data_evento readonly
    data data_recebimento readonly
    data status readonly
    data chave
    data codigo_status readonly
    data motivo_status readonly
    data numero_protocolo readonly
    data mensagem readonly
    data pdf_dacte readonly
    data xml_cte readonly
    data pdf_cancel readonly
    data xml_cancel readonly
    data tipo_evento readonly
    data digest_value readonly
    data baseUrl readonly
    data baseUrlID readonly
    data contingencia

    method new(cte) constructor
    method Emitir()
    method Consultar()
    method Cancelar()
    method BaixarPDFdoDACTE()
    method BaixarPDFdoCancelamento()
    method BaixarXMLdoCTe()
    method BaixarXMLdoCancelamento()
    method ConsultarSefaz()
    method Sincronizar()
    method ListarCTes()
    method defineBody()

end class

method new(cte) class TApiCTe
    ::cte := cte
    ::emitente := cte:emitente
    ::connected := false
    ::response := ""
    ::httpStatus := 0
    ::ContentType := ""
    ::token := appNuvemFiscal:token
    ::nuvemfiscal_uuid := cte:nuvemfiscal_uuid
    ::referencia_uuid := cte:referencia_uuid
    ::status := cte:situacao
    ::data_emissao := cte:dhEmi
    ::chave := cte:chCTe
    ::codigo_status := 0
    ::motivo_status := ""
    ::numero_protocolo := cte:nProt
    ::mensagem := ""
    ::tipo_evento := ""
    ::digest_value := ""
    ::contingencia := false
    ::data_evento := ""
    ::data_recebimento := ""

    if Empty(::token)
        apiLog({"type" => "Warning", "description" => "Token não definido para conexão com a Nuvem Fiscal"})
    else
        ::connection := GetMSXMLConnection()
        ::connected := !Empty(::connection)
    endif

    if (::cte:tpAmb == 1)   // API de Produção
        ::ambiente := "producao"
        ::baseUrl := "https://api.nuvemfiscal.com.br/cte"
    else    // API de Teste
        ::ambiente := "homologacao"
        ::baseUrl := "https://api.sandbox.nuvemfiscal.com.br/cte"
    endif

    if Empty(::nuvemfiscal_uuid)
        ::baseUrlID := ""
    else
        ::baseUrlID := ::baseUrl + "/" + ::nuvemfiscal_uuid
    endif

return self

method Emitir() class TApiCTe
    local res, hRes, hAutorizacao, sefazOff, sefazStatus, motivo
    local log, lEmitido := false

    if !::connected
        return lEmitido
    endif

    // Request Body
    ::defineBody()

    // Broadcast Parameters: connection, httpMethod, baseUrl, token, operation, body, content_type, accept
    res := Broadcast(::connection, "POST", ::baseUrl, ::token, "Emitir CTe", ::body, "application/json")

    ::httpStatus := res["http_status"]
    ::ContentType := res['ContentType']
    ::response := res['response']

    if res['error']

        ::status := "erro"
        ::mensagem := res["response"]

        if (::ContentType == "json")
            hRes := hb_jsonDecode(::response)
            if hb_HGetRef(hRes, "error")
                hRes := hRes["error"]
                ::mensagem := hRes["message"]
                ::data_evento := date_as_DateTime(Date(), false, false)
                ::data_recebimento := ::data_evento
                if ("o campo 'referencia' deve ser unico" $ desacentuar(Lower(::mensagem)))
                    if Empty(::nuvemfiscal_uuid)
                        saveLog({"Ao Emitir, retornou [o campo 'referencia' deve ser unico]", "Chamando ListarCTes() pela referência", "referencia: " + ::referencia_uuid})
                        res['error'] := ::ListarCTes()
                    else
                        saveLog({"Ao Emitir, retornou [o campo 'referencia' deve ser unico]", "Chamando Consultar() pelo uuid da nuvemfiscal", "nuvemfiscal_uuid: " + ::nuvemfiscal_uuid})
                        res['error'] := ::Consultar()
                    endif
                endif
            else
                log := {=>}
                log["type"] := "Warning"
                log["description"] := "Http Status: " + hb_ntos(res["http_status"]) + " | Não foi possível emitir CTe na api Nuvem Fiscal"
                log["content_type"] := res['ContentType']
                log["response"] := hRes
                apiLog(log)
            endif
        endif

        if !Empty(res["sefazOff"])

            sefazOff := res["sefazOff"]
            ::numero_protocolo := sefazOff["id"]
            ::codigo_status := sefazOff["codigo_status"]
            ::motivo_status := sefazOff["motivo_status"]
            sefazStatus := ::ConsultarSefaz()

            if !(sefazStatus["codigo_status"] == -1) .and. !(sefazStatus["codigo_status"] == 107)
                ::codigo_status := sefazStatus["codigo_status"]
                ::motivo_status := sefazStatus["motivo_status"]
                ::ambiente := sefazStatus["ambiente"]
                ::autorizador := sefazStatus["autorizador"]
                ::data_evento := ConvertUTCdataStampToLocal(sefazStatus["data_hora_consulta"])
                appData:cte_sefaz_offline := true
            endif
            res['error'] := true
        endif

    endif

    if !res['error']

        hRes := hb_jsonDecode(::response)
        ::nuvemfiscal_uuid := hRes['id']
        ::ambiente := hRes['ambiente']
        ::created_at := ConvertUTCdataStampToLocal(hRes['created_at'])
        ::status := hRes['status']
        ::data_emissao := ConvertUTCdataStampToLocal(hRes['data_emissao'])
        ::chave := hRes['chave']

        hAutorizacao := hRes['autorizacao']

        ::numero_protocolo := hb_HGetDef(hAutorizacao, 'numero_protocolo', hAutorizacao['id'])
        ::data_evento := ConvertUTCdataStampToLocal(hAutorizacao['data_evento'])

        if hb_HGetRef(hAutorizacao, 'data_recebimento')
            ::data_recebimento := ConvertUTCdataStampToLocal(hAutorizacao['data_recebimento'])
        else
            ::data_recebimento := ::data_evento
        endif

        if hb_HGetRef(hAutorizacao, 'codigo_status')
            ::codigo_status := hAutorizacao['codigo_status']
            ::motivo_status := hAutorizacao['motivo_status']
        else
            if hb_HGetRef(hAutorizacao, 'codigo_mensagem')
                ::codigo_status := hAutorizacao['codigo_mensagem']
                ::motivo_status := hAutorizacao['mensagem']
            endif
        endif

        ::tipo_evento := hAutorizacao['tipo_evento']
        ::digest_value := hAutorizacao['digest_value']

        switch ::codigo_status
            case 100
                ::status := "AUTORIZADO"
                lEmitido := true
                exit
            case 135
                ::status := "CANCELADO"
                lEmitido := true
                exit
            otherwise
                lEmitido := !res['error']
                motivo := Lower(Left(desacentuar(::motivo_status), 8))
                if (motivo == "rejeicao") .or. (Lower(::status) == "rejeitado")
                    ::status := "REJEITADO"
                    ::nuvemfiscal_uuid := ""
                    lEmitido := false
                endif
        endswitch

    endif

    if Empty(::nuvemfiscal_uuid)
        ::baseUrlID := ""
    else
        ::baseUrlID := ::baseUrl + "/" + ::nuvemfiscal_uuid
    endif

return lEmitido

method Consultar() class TApiCTe
    local log, res, hRes, hAutorizacao

    if !::connected
        return false
    endif

    // Broadcast Parameters: connection, httpMethod, baseUrlID, token, operation, body, content_type, accept
    res := Broadcast(::connection, "GET", ::baseUrlID, ::token, "Consultar CTe")

    ::httpStatus := res["http_status"]
    ::ContentType := res['ContentType']
    ::response := res['response']

    if res['error']

        log := {=>}
        log["type"] := "Warning"
        log["description"] := "Http Status: " + hb_ntos(res["http_status"]) + " | Não foi possível consultar CTe na api Nuvem Fiscal"
        log["content_type"] := res['ContentType']
        log["response"] := iif(res['ContentType'] == "json", hb_jsonDecode(::response), ::response)

        apiLog(log)

        ::status := "erro"
        ::mensagem := res["response"]

    else

        hRes := hb_jsonDecode(::response)
        ::nuvemfiscal_uuid := hRes['id']
        ::ambiente := hRes['ambiente']
        ::created_at := ConvertUTCdataStampToLocal(hRes['created_at'])
        ::status := hRes['status']
        ::data_emissao := ConvertUTCdataStampToLocal(hRes['data_emissao'])
        ::chave := hRes['chave']

        hAutorizacao := hRes['autorizacao']

        ::numero_protocolo := hb_HGetDef(hAutorizacao, 'numero_protocolo', hAutorizacao['id'])
        if hb_HGetRef(hAutorizacao, "digest_value")
            ::digest_value := hAutorizacao["digest_value"]
        endif
        ::data_evento := ConvertUTCdataStampToLocal(hAutorizacao['data_evento'])
        ::data_recebimento := ConvertUTCdataStampToLocal(hAutorizacao['data_recebimento'])

        if hb_HGetRef(hAutorizacao, 'codigo_status')
            ::codigo_status := hAutorizacao['codigo_status']
            ::motivo_status := hAutorizacao['motivo_status']
        else
            if hb_HGetRef(hAutorizacao, 'codigo_mensagem')
                ::codigo_status := hAutorizacao['codigo_mensagem']
                ::motivo_status := hAutorizacao['mensagem']
            endif
        endif

    endif

return !res['error']

method Cancelar() class TApiCTe
    local log, res, hRes, apiUrl := ::baseUrlID + "/cancelamento"

    if !::connected
        return false
    endif

    ::body := '{"justificativa":"Erro no preenchimento do Conhecimento de transporte Eletronico"}'

    // Broadcast Parameters: connection, httpMethod, apiUrl, token, operation, body, content_type, accept
    res := Broadcast(::connection, "POST", apiUrl, ::token, "Cancelar CTe", ::body, "application/json")

    ::httpStatus := res["http_status"]
    ::ContentType := res['ContentType']
    ::response := res['response']

    if res['error']
        log := {=>}
        log["type"] := "Warning"
        log["description"] := "Http Status: " + hb_ntos(res["http_status"]) + " | Não foi possível cancelar CTe na api Nuvem Fiscal"
        log["content_type"] := res['ContentType']
        log["response"] := iif(res['ContentType'] == "json", hb_jsonDecode(::response), ::response)

        apiLog(log)

        ::status := "erro"
        ::mensagem := res["response"]

    else

        hRes := hb_jsonDecode(::response)
        ::ambiente := hRes['ambiente']
        ::status := hRes['status']
        ::data_evento := ConvertUTCdataStampToLocal(hRes['data_evento'])
        ::data_recebimento := ConvertUTCdataStampToLocal(hRes['data_recebimento'])
        ::numero_protocolo := hb_HGetDef(hRes, 'numero_protocolo', hRes['id'])

        if hb_HGetRef(hRes, 'codigo_status')
            ::codigo_status := hRes['codigo_status']
            ::motivo_status := hRes['motivo_status']
        elseif hb_HGetRef(hRes, 'codigo_mensagem')
            ::codigo_status := hRes['codigo_mensagem']
            ::motivo_status := hRes['mensagem']
        else
            ::mensagem := res["response"]
        endif
        if hb_HGetRef(hRes, 'tipo_evento')
            ::tipo_evento := hRes['tipo_evento']
        endif

        if (::codigo_status == 135)
            ::status := "CANCELADO"
        endif

    endif

return !res['error']

method BaixarPDFdoDACTE() class TApiCTe
    local log, res, apiUrl := ::baseUrlID + "/pdf?logotipo=true"

    if !::connected
        ::cte:setUpdateEventos(::numero_protocolo, date_as_DateTime(Date(), false, false), ::codigo_status, "Não é possível baixar PDF, API Nuvem Fiscal não conectado")
        apiLog({"type" => "Warning", "description" => "Sem conexão com a API Nuvem Fiscal"})
        return false
    endif

    // Broadcast Parameters: connection, httpMethod, apiUrl, token, operation, body, content_type, accept
    res := Broadcast(::connection, "GET", apiUrl, ::token, "Baixar PDF do DACTE", nil, nil, "*/*")

    ::httpStatus := res["http_status"]
    ::ContentType := res['ContentType']
    ::response := res['response']   // Response Schema: "*/*", não retorna json, somente o binário

    if res['error']
        log := {=>}
        log["type"] := "Warning"
        log["description"] := "Http Status: " + hb_ntos(res["http_status"]) + " | Não foi possível baixar PDF do DACTE na api Nuvem Fiscal"
        log["content_type"] := res['ContentType']
        log["response"] := iif(res['ContentType'] == "json", hb_jsonDecode(::response), ::response)

        apiLog(log)

        ::status := "erro"
        ::mensagem := res["response"]
    else
        ::pdf_dacte := ::response
    endif

return !res['error']

method BaixarPDFdoCancelamento() class TApiCTe
    local log, res, apiUrl := ::baseUrlID + "/cancelamento/pdf?logotipo=true"

    if !::connected
        ::cte:setUpdateEventos(::numero_protocolo, date_as_DateTime(Date(), false, false), ::codigo_status, "Não é possível baixar PDF do Cancelamento, API Nuvem Fiscal não conectado")
        apiLog({"type" => "Warning", "description" => "Sem conexão com a API Nuvem Fiscal"})
        return false
    endif

    // Broadcast Parameters: connection, httpMethod, apiUrl, token, operation, body, content_type, accept
    res := Broadcast(::connection, "GET", apiUrl, ::token, "Baixar PDF do CTE CANCELADO", nil, nil, "*/*")

    ::httpStatus := res["http_status"]
    ::ContentType := res['ContentType']
    ::response := res['response']   // Response Schema: "*/*", não retorna json, somente o binário

    if res['error']
        log := {=>}
        log["type"] := "Warning"
        log["description"] := "Http Status: " + hb_ntos(res["http_status"]) + " | Não foi possível baixar PDF do CTE CANCELADO na api Nuvem Fiscal"
        log["content_type"] := res['ContentType']
        log["response"] := iif(res['ContentType'] == "json", hb_jsonDecode(::response), ::response)

        apiLog(log)

        ::status := "erro"
        ::mensagem := res["response"]
    else
        ::pdf_cancel := ::response
    endif

return !res['error']

method BaixarXMLdoCTe() class TApiCTe
    local log, res, apiUrl := ::baseUrlID + "/xml"

    // ::connecHttp := GetWinHttpConnection()
    // ::connected := !Empty(::connecHttp)

    if !::connected
        ::cte:setUpdateEventos(::numero_protocolo, date_as_DateTime(Date(), false, false), ::codigo_status, "Não é possível baixar XML, API Nuvem Fiscal não conectado")
        apiLog({"type" => "Warning", "description" => "Sem conexão com a API Nuvem Fiscal via WinHttp.WinHttpRequest.5.1"})
        return false
    endif

    // Broadcast Parameters: connection, httpMethod, apiUrl, token, operation, body, content_type, accept
    res := Broadcast(::connection, "GET", apiUrl, ::token, "Baixar XML do CTe", nil, nil, "*/*")

    ::httpStatus := res["http_status"]
    ::ContentType := res['ContentType']
    ::response := res['response']

    if res['error'] .or. !(res["error_code"] == 0)
        log := {=>}
        log["type"] := "Warning"
        log["description"] := "Http Status: " + hb_ntos(res["http_status"]) + " | Não foi possível baixar XML do CTe na api Nuvem Fiscal"
        log["content_type"] := res['ContentType']
        log["response"] := iif(res['ContentType'] == "json", hb_jsonDecode(::response), ::response)

        apiLog(log)

        ::status := "erro"
        ::mensagem := res["response"]
    else
        ::xml_cte := ::response
    endif

return !res['error']

method BaixarXMLdoCancelamento() class TApiCTe
    local log, res, apiUrl := ::baseUrlID + "/cancelamento/xml"

    if !::connected
        ::cte:setUpdateEventos(::numero_protocolo, date_as_DateTime(Date(), false, false), ::codigo_status, "Não é possível baixar XML do Cancelamento, API Nuvem Fiscal não conectado")
        apiLog({"type" => "Warning", "description" => "Sem conexão com a API Nuvem Fiscal"})
        return false
    endif

    // Broadcast Parameters: connection, httpMethod, apiUrl, token, operation, body, content_type, accept
    res := Broadcast(::connection, "GET", apiUrl, ::token, "Baixar XML do CTE CANCELADO", nil, nil, "*/*")

    ::httpStatus := res["http_status"]
    ::ContentType := res['ContentType']
    ::response := res['response']

    if res['error']
        log := {=>}
        log["type"] := "Warning"
        log["description"] := "Http Status: " + hb_ntos(res["http_status"]) + " | Não foi possível baixar XML do CTE CANCELADO na api Nuvem Fiscal"
        log["content_type"] := res['ContentType']
        log["response"] := iif(res['ContentType'] == "json", hb_jsonDecode(::response), ::response)

        apiLog(log)

        ::status := "erro"
        ::mensagem := res["response"]
    else
        ::xml_cancel := ::response
    endif

return !res['error']

method ConsultarSefaz() class TApiCTe
    local log, res, apiUrl := ::baseUrl + "/sefaz/status?cpf_cnpj=" + ::emitente:CNPJ
    local sefaz := {"codigo_status" => -1}

    // Se está em contigência, consulta a Sefaz Virtual SVC-RS se já está operando
    if ::contingencia
        apiUrl += chr(38) + "autorizador=RS"
    endif

    // Broadcast Parameters: connection, httpMethod, apiUrl, token, operation, body, content_type, accept
    res := Broadcast(::connection, "GET", apiUrl, ::token, "CTe: Consultar Status Sefaz", nil, nil, "*/*")
    ::response := res['response']

    if res["error"]
        log := {=>}
        log["type"] := "Warning"
        log["description"] := "Http Status: " + hb_ntos(res["http_status"]) + " | Não foi possível consultar status SEFAZ, parece que SEFAZ/API-NUVEM FISCAL esta fora do ar"
        log["content_type"] := res['ContentType']
        log["response"] := iif(res['ContentType'] == "json", hb_jsonDecode(::response), ::response)

        apiLog(log)

        ::status := "erro"
        ::mensagem := res["response"]
    else
        sefaz := hb_jsonDecode(res["response"])
    endif

return sefaz

method Sincronizar() class TApiCTe
    local log, res, hRes, motivo, apiUrl := ::baseUrlID + "/sincronizar"
    local lEmitido := false

    if !::connected
        ::cte:setUpdateEventos(::numero_protocolo, date_as_DateTime(Date(), false, false), ::codigo_status, "Não é possível sincroinizar CTe, API Nuvem Fiscal não conectado")
        apiLog({"type" => "Warning", "description" => "Sem conexão com a API Nuvem Fiscal"})
        return lEmitido
    endif

    // Broadcast Parameters: connection, httpMethod, apiUrl, token, operation, body, content_type, accept
    res := Broadcast(::connection, "POST", apiUrl, ::token, "Sincronizar CTe a partir da SEFAZ", nil, nil, "*/*")

    ::httpStatus := res["http_status"]
    ::ContentType := res['ContentType']
    ::response := res['response']

    if res['error']
        log := {=>}
        log["type"] := "Warning"
        log["description"] := "Http Status: " + hb_ntos(res["http_status"]) + " | Não foi possível sincronizar CTe com a API Nuvem Fiscal"
        log["content_type"] := res['ContentType']
        log["response"] := iif(res['ContentType'] == "json", hb_jsonDecode(::response), ::response)

        apiLog(log)

        ::status := "erro"
        ::mensagem := res["response"]
    else

        hRes := hb_jsonDecode(::response)
        ::codigo_status := hRes["codigo_status"]
        ::motivo_status := hRes["motivo_status"]
        ::data_recebimento := ConvertUTCdataStampToLocal(hRes['data_recebimento'])
        ::chave := hRes["chave"]

        switch ::codigo_status
            case 100
                ::status := "AUTORIZADO"
                lEmitido := true
                exit
            case 135
                ::status := "CANCELADO"
                lEmitido := true
                exit
            otherwise
                lEmitido := !res['error']
                motivo := Lower(Left(desacentuar(::motivo_status), 8))
                if (motivo == "rejeicao") .or. (Lower(::status) == "rejeitado")
                    ::status := "REJEITADO"
                    ::nuvemfiscal_uuid := ""
                    lEmitido := false
                endif

        endswitch

    endif

return lEmitido

method ListarCTes() class TApiCTe
    local log, res, hRes, aRes := {}, hCTe, hAutorizacao
    local apiUrl := ::baseUrl + "?cpf_cnpj=" + ::emitente:CNPJ

    if !::connected
        return false
    endif

    apiUrl += chr(38) + "referencia=" + ::referencia_uuid
    apiUrl += chr(38) + "ambiente=" + ::ambiente

    // Broadcast Parameters: connection, httpMethod, apiUrl, token, operation, body, content_type, accept
    res := Broadcast(::connection, "GET", apiUrl, ::token, "Listar CTes por referencia_uuid")

    ::httpStatus := res["http_status"]
    ::ContentType := res['ContentType']
    ::response := res['response']

    if res['error']
        log := {=>}
        log["type"] := "Warning"
        log["description"] := "Http Status: " + hb_ntos(res["http_status"]) + " | Não foi possível listar CTes por referencia_uuid na API Nuvem Fiscal"
        log["content_type"] := res['ContentType']
        log["response"] := iif(res['ContentType'] == "json", hb_jsonDecode(::response), ::response)

        apiLog(log)

        ::status := "erro"
        ::mensagem := res["response"]
    else
        hRes := hb_jsonDecode(::response)
        if hb_HGetRef(hRes, "data")
            aRes := hRes["data"]
        endif

        if Empty(aRes)
            ::codigo_status := 0
            ::motivo_status := "CTe nao encontrado na Consulta por referencia_uuid"
            res["error"] := true
            saveLog({"CTe nao encontrado na Consulta ListarCTes() por referencia_uuid", "referência: " + ::referencia_uuid})
        else

            // Por referencia, só retorna um elemento no array
            hCTe := aRes[1]
            ::nuvemfiscal_uuid := hCTe['id']
            ::ambiente := hCTe['ambiente']
            ::created_at := ConvertUTCdataStampToLocal(hCTe['created_at'])
            ::status := hCTe['status']
            ::data_emissao := ConvertUTCdataStampToLocal(hCTe['data_emissao'])
            ::chave := hCTe['chave']

            hAutorizacao := hCTe['autorizacao']

            ::numero_protocolo := hb_HGetDef(hAutorizacao, 'numero_protocolo', hAutorizacao['id'])
            ::data_evento := ConvertUTCdataStampToLocal(hAutorizacao['data_evento'])

            if (::status == "pendente")
                ::baseUrlID := ::baseUrl + "/" + ::nuvemfiscal_uuid
                SysWait(7)
                res['error'] := ::Consultar()
            else
                if hb_HGetRef(hAutorizacao, 'data_recebimento')
                    ::data_recebimento := ConvertUTCdataStampToLocal(hAutorizacao['data_recebimento'])
                endif
                if hb_HGetRef(hAutorizacao, 'codigo_status')
                    ::codigo_status := hAutorizacao['codigo_status']
                    ::motivo_status := hAutorizacao['motivo_status']
                elseif hb_HGetRef(hAutorizacao, 'codigo_mensagem')
                    ::codigo_status := hAutorizacao['codigo_mensagem']
                    ::motivo_status := hAutorizacao['mensagem']
                endif
                if hb_HGetRef(hAutorizacao, "digest_value")
                    ::digest_value := hAutorizacao['digest_value']
                endif
            endif

            // Na API Listar CTe/MDFe, mesmo que o status seja cancelado ou encerrado, o codigo_status vem 100 e motivo_status de autorização
            if (::status == "autorizado")
                ::codigo_status := 100
                ::motivo_status := "Autorizado o uso do CT-e."
            elseif (::status == "cancelado")
                ::codigo_status := 135
                ::motivo_status := "Evento registrado e vinculado ao CT-e"
            endif

            ::cte:setUpdateCte('cte_chave', ::chave)
            ::cte:setUpdateCte('nuvemfiscal_uuid', ::nuvemfiscal_uuid)

        endif

    endif

    if !Empty(::nuvemfiscal_uuid) .and. !(::nuvemfiscal_uuid $ ::baseUrlID)
        ::baseUrlID := ::baseUrl + "/" + ::nuvemfiscal_uuid
    endif

return !res['error']

// Request Body
method defineBody() class TApiCTe
    local hBody, infCte,ide, toma, cod_sit_trib, occ
    local compl, fluxo, entrega, ObsContFisco
    local emite, remet, exped, receb, desti, ender
    local vPrest, Comp, imp, ICMS
    local infCteNorm, infCarga, infDoc, docAnexos, infModal, rodo, aereo, tarifa, tpTar, CL
    local clieEMail, pos, obs, hComp, hDoc, tag, ambiente
    // Doc: https://dev.nuvemfiscal.com.br/docs/api#tag/Cte/operation/EmitirCte

    // Tag ide
    ide := {=>}
    ide["cUF"] := ::cte:cUF
    ide["cCT"] := ::cte:cCT
    ide["CFOP"] := ::cte:CFOP
    ide["natOp"] := ::cte:natOp
    ide["mod"] := ::cte:modelo
    ide["serie"] := ::cte:serie
    ide["nCT"] := ::cte:nCT
    ide["dhEmi"] := ::cte:dhEmi
    ide["tpImp"] :=  ::cte:tpImp
    ide["tpEmis"] := ::cte:tpEmis
    ide["tpAmb"] := ::cte:tpAmb
    ide["tpCTe"] := ::cte:tpCTe
    ide["procEmi"] := 0                     // 0 - Emissão de CT-e com aplicativo do contribuinte
    ide["verProc"] := Left(appData:version, hb_RAt('.', appData:version)) + '0'

    if (::cte:indGlobalizado == 1)
        ide["indGlobalizado"] := 1
    endif

    ide["cMunEnv"] := ::emitente:cMunEnv
    ide["xMunEnv"] := ::emitente:xMunEnv
    ide["UFEnv"] := ::emitente:UF
    ide["modal"] := ::cte:modal
    ide["tpServ"] := ::cte:tpServ
    ide["cMunIni"] := ::cte:cMunIni
    ide["xMunIni"] := ::cte:xMunIni
    ide["UFIni"] := ::cte:UFIni
    ide["cMunFim"] := ::cte:cMunFim
    ide["xMunFim"] := ::cte:xMunFim
    ide["UFFim"] := ::cte:UFFim
    ide["retira"] := ::cte:retira

    if !Empty(::cte:xDetRetira)
        ide["xDetRetira"] := ::cte:xDetRetira
    endif

    ide["indIEToma"] := ::cte:indIEToma

    // Tag toma3 ou toma4
    if (::cte:tomador == 4)
        toma := {=>}
        toma["toma"] := 4

        if Empty(::cte:tom_cnpj)
            toma["CPF"] := ::cte:tom_cpf
        else
            toma["CNPJ"] := ::cte:tom_cnpj
        endif
        if !Empty(::cte:tom_ie)
            toma["IE"] := ::cte:tom_ie
        endif
        toma["xNome"] := ::cte:tom_xNome
        if !Empty(::cte:tom_xFant)
            toma["xFant"] := ::cte:tom_xFant
        endif
        if !Empty(::cte:tom_fone)
            toma["fone"] := ::cte:tom_fone
        endif

        ender := {=>}
        ender["xLgr"] := ::cte:tom_end_logradouro
        ender["nro"] := ::cte:tom_end_numero
        if !Empty(::cte:tom_end_complemento)
            ender["xCpl"] := ::cte:tom_end_complemento
        endif
        ender["xBairro"] := ::cte:tom_end_bairro
        ender["cMun"] := ::cte:tom_cid_codigo_municipio
        ender["xMun"] := ::cte:tom_cid_municipio
        ender["CEP"] := ::cte:tom_end_cep
        ender["UF"] := ::cte:tom_cid_uf
        ender["cPais"] := "1058"
        ender["xPais"] := "BRASIL"

        toma["enderToma"] := ender
        ender := nil

        if !Empty(::cte:tom_email)
            toma["email"] := ::cte:tom_email
        endif

        ide["toma4"] := toma
        toma := nil

    else
        ide["toma3"] := {"toma" => ::cte:tomador}
    endif

    // tpEmis: 1 - Normal; 5 - Contingência FSDA; 7 - Autorização pela SVC-RS; 8 - Autorização pela SVC-SP
    if (::contingencia)
        ide["tpEmis"] := 7      // 7 - Autorização pela SVC-RS
        ide["dhCont"] := StrTran(::data_emissao, " ", "T")
        ide["xJust"] := "SEFAZ SP: " + hb_ntos(::codigo_status) + " - " + ::motivo_status
    endif

    // Tag compl
    compl := {=>}
    if !Empty(::cte:xCaracAd)
        compl["xCaracAd"] := ::cte:xCaracAd
    endif
    if !Empty(::cte:xCaracSer)
        compl["xCaracSer"] := ::cte:xCaracSer
    endif
    if !Empty(::cte:xEmi)
        compl["xEmi"] := ::cte:xEmi
    endif

    if (::cte:modal == "02")
        // Tag fluxo para modal Aéreo
        fluxo := {=>}
        fluxo["xOrig"] := ::cte:xOrig
        fluxo["pass"] := {{"xPass" => ::cte:xPass}}
        fluxo["xDest"] := ::cte:xDest
        compl["fluxo"] := fluxo
        fluxo := nil
    endif

    // Tag Entrega: Tipo de data/período programado para a entrega: 0 - Sem data definida; 1 - Na data; 2 - Até a data; 3 - A partir da data; 4 – No período
    entrega := {=>}
    do case
    case (::cte:tpPer == 0)
        entrega["semData"] := {"tpPer" => 0}
    case (hb_ntos(::cte:tpPer) $ '1|2|3')
        entrega["comData"] := {"tpPer" => ::cte:tpPer, "dProg" => ::cte:dProg}
    case (::cte:tpPer == 4)
        entrega["noPeriodo"] := {"tpPer" => ::cte:tpPer, "dIni" => ::cte:dIni, "dFim" => ::cte:dFim}
    endcase
    // Tipo de hora/período programado para a entrega: 0 - Sem hora definida; 1 - Na hora; 2 - Até a hora; 3 - A partir da hora; 4 – No intervalo de tempo
    do case
    case (::cte:tpHor == 0)
        entrega["semHora"] := {"tpHor" => 0}
    case (hb_ntos(::cte:tpHor) $ '1|2|3')
        entrega["comHora"] := {"tpHor" => ::cte:tpHor, "hProg" => ::cte:hProg}
    case (::cte:tpHor == 4)
        entrega["noInter"] := {"tpHor" => ::cte:tpHor, "hIni" => ::cte:hIni, "hFim" => ::cte:hFim}
    endcase

    if !Empty(entrega)
        compl["Entrega"] := entrega
    endif
    entrega := nil

    compl["origCalc"] := ::cte:xMunIni
    compl["destCalc"] := ::cte:xMunFim

    if !Empty(::cte:xObs)
        compl["xObs"] := StrTran(StrTran(::cte:xObs, "\n", " | "), hb_eol(), " | ")
    endif

    if !Empty(::cte:obs_contr)
        ObsContFisco := {}
        for each obs in ::cte:obs_contr
            AAdd(ObsContFisco, {"xCampo" => obs["xCampo"], "xTexto" => obs["xTexto"]})
        next
        compl["ObsCont"] := ObsContFisco
        ObsContFisco := nil
    endif

    if ::contingencia
        if hb_HGetRef(compl, "ObsCont")
            AAdd(compl["ObsCont"], {"xCampo" => "SVC-RS", "xTexto" => "EMISSAO EM CONTINGENCIA"})
        else
            compl["ObsCont"] := {{"xCampo" => "SVC-RS", "xTexto" => "EMISSAO EM CONTINGENCIA"}, {"xCampo" => "Emissor", "xTexto" => "DFeMonitor"}}
        endif
    endif

    if !Empty(::cte:obs_fisco)
        ObsContFisco := {}
        for each obs in ::cte:obs_fisco
            AAdd(ObsContFisco, {"xCampo" => obs["xCampo"], "xTexto" => obs["xTexto"]})
        next
        compl["ObsFisco"] := ObsContFisco
        ObsContFisco := nil
    endif

    // Tag emit
    emite := {=>}
    emite["CNPJ"] := ::emitente:CNPJ

    if !Empty(::emitente:IE)
        emite["IE"] := ::emitente:IE
    endif

    emite["xNome"] := ::emitente:xNome

    if !Empty(::emitente:xFant)
        emite["xFant"] := ::emitente:xFant
    endif

    ender := {=>}
    ender["xLgr"] := ::emitente:xLgr
    ender["nro"] := ::emitente:nro
    if !Empty(::emitente:xCpl)
        ender["xCpl"] := ::emitente:xCpl
    endif
    ender["xBairro"] := ::emitente:xBairro
    ender["cMun"] := ::emitente:cMunEnv
    ender["xMun"] := ::emitente:xMunEnv
    ender["CEP"] := ::emitente:CEP
    ender["UF"] := ::emitente:UF
    ender["fone"] :=::emitente:fone

    emite["enderEmit"] := ender
    ender := nil

    /*
        NT 2022.001v.1.00 - A partir de 01/07/22 nova tag obrigatória CRT - Código do Regime Tributário
        1 - Simples Nacional;
        2 - Simples Nacional, excesso sublimite de receita bruta;
        3 - Regime Normal;
        4 - Simples Naciona - Microempreendedor Individual (MEI);
        AP = 1 e LW =3
        ** Versão 3.00: Deveria ter entrado em 01/07 mas não entrou, Sefaz não seguiu data prevista no manual!
        ** Versão 4.00: Testar se aceita ou retorna erro como na versão 3.00 do CTe
    */
    emite["CRT"] := ::emitente:CRT

    // Tag rem
    remet := {=>}
    if !Empty(::cte:rem_cnpj) .or. !Empty(::cte:rem_cpf)
        if Empty(::cte:rem_cnpj)
            remet["CPF"] := ::cte:rem_cpf
        else
            remet["CNPJ"] := ::cte:rem_cnpj
            if !Empty(::cte:rem_ie)
                remet["IE"] := ::cte:rem_ie
            endif
        endif

        remet["xNome"] := ::cte:rem_razao_social
        if !Empty(::cte:rem_nome_fantasia)
            remet["xFant"] := ::cte:rem_nome_fantasia
        endif
        if !Empty(::cte:rem_fone)
            remet["fone"] := ::cte:rem_fone
        endif

        ender := {=>}
        ender["xLgr"] := ::cte:rem_end_logradouro
        ender["nro"] := ::cte:rem_end_numero
        if !Empty(::cte:rem_end_complemento)
            ender["xCpl"] := ::cte:rem_end_complemento
        endif
        ender["xBairro"] := ::cte:rem_end_bairro
        ender["cMun"] := ::cte:rem_cid_codigo_municipio
        ender["xMun"] := ::cte:rem_cid_municipio
        ender["CEP"] := ::cte:rem_end_cep
        ender["UF"] := ::cte:rem_cid_uf

        remet["enderReme"] := ender
        ender := nil

        if !Empty(::cte:rem_email)
            remet["email"] := ::cte:rem_email
        endif
    endif

    // Tag exped
    exped := {=>}
    if !Empty(::cte:exp_cnpj) .or. !Empty(::cte:exp_cpf)
        if Empty(::cte:exp_cnpj)
            exped["CPF"] := ::cte:exp_cpf
        else
            exped["CNPJ"] := ::cte:exp_cnpj
            if !Empty(::cte:exp_ie)
                exped["IE"] := ::cte:exp_ie
            endif
        endif

        exped["xNome"] := ::cte:exp_razao_social
        if !Empty(::cte:exp_fone)
            exped["fone"] := ::cte:exp_fone
        endif

        ender := {=>}
        ender["xLgr"] := ::cte:exp_end_logradouro
        ender["nro"] := ::cte:exp_end_numero
        if !Empty(::cte:exp_end_complemento)
            ender["xCpl"] := ::cte:exp_end_complemento
        endif
        ender["xBairro"] := ::cte:exp_end_bairro
        ender["cMun"] := ::cte:exp_cid_codigo_municipio
        ender["xMun"] := ::cte:exp_cid_municipio
        ender["CEP"] := ::cte:exp_end_cep
        ender["UF"] := ::cte:exp_cid_uf

        exped["enderExped"] := ender
        ender := nil

        if !Empty(::cte:exp_email)
            exped["email"] := ::cte:exp_email
        endif
    endif

    // Tag receb
    receb := {=>}
    if !Empty(::cte:rec_cnpj) .or. !Empty(::cte:rec_cpf)
        if Empty(::cte:rec_cnpj)
            receb["CPF"] := ::cte:rec_cpf
        else
            receb["CNPJ"] := ::cte:rec_cnpj
            if !Empty(::cte:rec_ie)
                receb["IE"] := ::cte:rec_ie
            endif
        endif

        receb["xNome"] := ::cte:rec_razao_social
        if !Empty(::cte:rec_fone)
            receb["fone"] := ::cte:rec_fone
        endif

        ender := {=>}
        ender["xLgr"] := ::cte:rec_end_logradouro
        ender["nro"] := ::cte:rec_end_numero
        if !Empty(::cte:rec_end_complemento)
            ender["xCpl"] := ::cte:rec_end_complemento
        endif
        ender["xBairro"] := ::cte:rec_end_bairro
        ender["cMun"] := ::cte:rec_cid_codigo_municipio
        ender["xMun"] := ::cte:rec_cid_municipio
        ender["CEP"] := ::cte:rec_end_cep
        ender["UF"] := ::cte:rec_cid_uf

        receb["enderReceb"] := ender
        ender := nil

        if !Empty(::cte:rec_email)
            receb["email"] := ::cte:rec_email
        endif
    endif

    // Tag dest
    desti := {=>}
    if !Empty(::cte:des_cnpj) .or. !Empty(::cte:des_cpf)
        if Empty(::cte:des_cnpj)
            desti["CPF"] := ::cte:des_cpf
        else
            desti["CNPJ"] := ::cte:des_cnpj
            if !Empty(::cte:des_ie)
                desti["IE"] := ::cte:des_ie
            endif
        endif

        desti["xNome"] := ::cte:des_razao_social
        if !Empty(::cte:des_fone)
            desti["fone"] := ::cte:des_fone
        endif

        if !Empty(::cte:des_ISUF)
            desti["ISUF"] := ::cte:des_ISUF
        endif

        ender := {=>}
        ender["xLgr"] := ::cte:des_end_logradouro
        ender["nro"] := ::cte:des_end_numero
        if !Empty(::cte:des_end_complemento)
            ender["xCpl"] := ::cte:des_end_complemento
        endif
        ender["xBairro"] := ::cte:des_end_bairro
        ender["cMun"] := ::cte:des_cid_codigo_municipio
        ender["xMun"] := ::cte:des_cid_municipio
        ender["CEP"] := ::cte:des_end_cep
        ender["UF"] := ::cte:des_cid_uf

        desti["enderDest"] := ender
        ender := nil

        if !Empty(::cte:des_email)
            desti["email"] := ::cte:des_email
        endif
    endif

    infCte := {=>}
    infCte["versao"] := ::emitente:cte_versao_xml
    infCte["ide"] := ide
    infCte["compl"] := compl
    infCte["emit"] := emite

    if !Empty(remet)
        infCte["rem"] := remet
    endif
    if !Empty(exped)
        infCte["exped"] := exped
    endif
    if !Empty(receb)
        infCte["receb"] := receb
    endif
    if !Empty(desti)
        infCte["dest"] := desti
    endif

    // Limpa e libera as variáveis deixando o Garbage Collector do Harbour limpar a memória
    ide := compl := emite := remet := exped := receb := desti := nil

    vPrest := {=>}
    vPrest["vTPrest"] := ::cte:vTPrest
    vPrest["vRec"] := ::cte:vTPrest

    if !Empty(::cte:comp_calc)
        Comp := {}
        for each hComp in ::cte:comp_calc
            AAdd(Comp, {"xNome" => Left(AllTrim(hComp["xNome"]), 15), "vComp" => hComp["vComp"]})
        next
        vPrest["Comp"] := Comp
        Comp := nil
    endif

    infCte["vPrest"] := vPrest
    vPrest := nil

    ICMS := {=>}
    cod_sit_trib := AllTrim(Lower(desacentuar(::cte:codigo_sit_tributaria)))

    switch cod_sit_trib
        case "00 - tributacao normal do icms"
            ICMS["ICMS00"] := {"CST" => "00", "vBC" => ::cte:vBC, "pICMS" => ::cte:pICMS, "vICMS" => ::cte:vICMS}
            exit
        case "20 - tributacao com reducao de bc do icms"
            ICMS["ICMS20"] := {"CST" => "20", "pRedBC" => ::cte:pRedBC, "vBC" => ::cte:vBC, "pICMS" => ::cte:pICMS, "vICMS" => ::cte:vICMS}
            exit
        case "60 - icms cobrado anteriormente por substituicao tributaria"
            ICMS["ICMS60"] := {"CST" => "60", "vBCSTRet" => ::cte:vBC, "vICMSSTRet" => ::cte:vICMS, "pICMSSTRet" => ::cte:pICMS, "vCred" => ::cte:vCred}
            exit
        case "90 - icms outros"
            ICMS["ICMS90"] := {"CST" => "90", "pRedBC" => ::cte:pRedBC, "vBC" => ::cte:vBC, "pICMS" => ::cte:pICMS, "vICMS" => ::cte:vICMS, "vCred" => ::cte:vCred}
                exit
        case "90 - icms devido a uf de origem da prestacao, quando diferente da uf emitente"
            ICMS["ICMSOutraUF"] := {"CST" => "90", "pRedBCOutraUF" => ::cte:pRedBC, "vBCOutraUF" => ::cte:vBC, "pICMSOutraUF" => ::cte:pICMS, "vICMSOutraUF" => ::cte:vICMS}
            exit
        case "simples nacional"
            ICMS["ICMSSN"] := {"CST" => "90", "indSN" => 1}
            exit
        otherwise
            cod_sit_trib := hb_ULeft(cod_sit_trib, 2)
            if (cod_sit_trib $ "40|41|51")
                // 45 - ICMS Isento, não Tributado ou diferido
                ICMS["ICMS45"] := {"CST" => cod_sit_trib}
            endif
    endswitch

    imp := {=>}
    imp["ICMS"] := ICMS
    imp["vTotTrib"] := ::cte:vTotTrib

    if !Empty(::cte:infAdFisco)
        imp["infAdFisco"] := ::cte:infAdFisco
    endif
    if !Empty(::cte:calc_difal)
        imp["ICMSUFFim"] := {"vBCUFFim" => ::cte:vTPrest, ;
                                 "pFCPUFFim" => ::cte:calc_difal["pFCPUFFim"], ;
                                 "pICMSUFFim" => ::cte:calc_difal["pICMSUFFim"], ;
                                 "pICMSInter" => ::cte:calc_difal["pICMSInter"], ;
                                 "vFCPUFFim" => ::cte:calc_difal["vFCPUFFim"], ;
                                 "vICMSUFFim" => ::cte:calc_difal["vICMSUFFim"], ;
                                 "vICMSUFIni" => ::cte:calc_difal["vICMSUFIni"]}
     endif

    infCte["imp"] := imp
    imp := ICMS := nil

    if (hb_ntos(::cte:tpCTe) $ "03")
        // 0 - CT-e Normal ou 3 - CT-e de Substituição

        infCarga := {=>}
        infCarga["vCarga"] := ::cte:vCarga
        infCarga["proPred"] := ::cte:proPred
        if !Empty(::cte:xOutCat)
            infCarga["xOutCat"] := ::cte:xOutCat
        endif

        SET FIXED ON
        SET DECIMALS TO 4

        infCarga["infQ"] := {{"cUnid" => "01", "tpMed" => "PESO BRUTO", "qCarga" => ::cte:peso_bruto}, ;
                             {"cUnid" => "01", "tpMed" => "PESO BC", "qCarga" => ::cte:peso_bc}, ;
                             {"cUnid" => "01", "tpMed" => "PESO CUBADO", "qCarga" => ::cte:peso_cubado}, ;
                             {"cUnid" => "00", "tpMed" => "PESO CUBAGEM", "qCarga" => ::cte:cubagem_m3}, ;
                             {"cUnid" => "03", "tpMed" => "VOLS.", "qCarga" => ::cte:qtde_volumes} ;
                            }

        // vCargaAverb // Não utilizado ou desnecessário

        SET DECIMALS TO
        SET FIXED OFF

        infCteNorm := {=>}
        infCteNorm["infCarga"] := infCarga
        infCarga := nil

        infDoc := {=>}
        docAnexos := {}

        switch ::cte:tipo_doc_anexo
            case 1 // 1-Nota Fiscal
                tag := "infNF"
                for each hDoc in ::cte:doc_anexo
                    if !hb_HGetRef(hDoc, "dPrev")
                        hDoc["dPrev"] := Date() + 2
                    endif

                    AAdd(docAnexos, {"mod" => PadL(hDoc["modelo"], 2, "0"), ;
                                     "serie" => PadL(hDoc["serie"], 3, "0"), ;
                                     "nDoc" => hDoc["nDoc"], ;
                                     "dEmi" => hDoc["dEmi"], ;
                                     "vBC" => hDoc["vBC"], ;
                                     "vICMS" => hDoc["vICMS"], ;
                                     "vBCST" => hDoc["vBCST"], ;
                                     "vST" => hDoc["vST"], ;
                                     "vProd" => hDoc["vProd"], ;
                                     "vNF" => hDoc["vNF"], ;
                                     "nCFOP" => hDoc["nCFOP"], ;
                                     "nPeso" => hDoc["nPeso"], ;
                                     "PIN" => hDoc["PIN"], ;
                                     "dPrev" => hDoc["dPrev"] ;
                                })
                next
                exit
            case 2 // 2-NFe
                tag := "infNFe"
                for each hDoc in ::cte:doc_anexo
                    if Empty(hDoc["PIN"])
                        AAdd(docAnexos, {"chave" => hDoc["chave"]})
                    else
                        AAdd(docAnexos, {"chave" => hDoc["chave"], "PIN" => hDoc["PIN"]})
                    endif
                next
                exit
            case 3 // 3-Declarações, outros
                tag := "infOutros"
                for each hDoc in ::cte:doc_anexo
                    AAdd(docAnexos, {"tpDoc" => PadL(hDoc["tpDoc"], 2, "0"), ;
                                        "descOutros" => hDoc["descOutros"], ;
                                        "nDoc" => hDoc["nDoc"], ;
                                        "dEmi" => hDoc["dEmi"], ;
                                        "vDocFisc" => hDoc["vDocFisc"] ;
                                    })
                next
                exit
        endswitch
        // infUnidCarga  -- Opcional. Informação indisponível na emissão do CTe
        // infUnidTransp -- Opcional. Informação indisponível na emissão do CTe

        infDoc[tag] := docAnexos
        infCteNorm["infDoc"] := infDoc
        infDoc := docAnexos := nil

        if !Empty(::cte:docAnt)
            infCteNorm["docAnt"] := ::cte:docAnt
        endif

        infModal := {=>}
        infModal["versaoModal"] := ::cte:versao_xml

        if (::cte:tpCTe == 0)
            // tp::cte: 0 - Normal
            if (::cte:tpServ == 0)
                // tpServ: 0 - Normal
                if (::cte:modal == "01")
                    // Rodo: Informação do modal rodoviário

                    rodo := {=>}
                    rodo["RNTRC"] := ::emitente:RNTRC

                    // Debug
                    saveLog('Qtde Elementos Array cte:rodoOcc: ' + hb_ntos(hmg_len(::cte:rodoOcc)))
                    /*
                    ********************************
                    * Rotina com error
                    ********************************
                    if !Empty(::cte:rodoOcc)
                        // Ordens de Coletas
                        rodo["occ"] := {}
                        for each occ in ::cte:rodoOcc
                            if Empty(occ["serie"])
                                AAdd(rodo["occ"], ;
                                    {"nOcc" => occ["nOcc"], ;
                                     "dEmi" => occ["dEmi"], ;
                                     "emiOcc" => {"CNPJ" => occ["CNPJ"], "IE" => occ["IE"], "UF" => occ["UF"]} ;
                                    })
                            else
                                AAdd(rodo["occ"], ;
                                    {"serie" => occ["serie"], ;
                                     "nOcc" => occ["nOcc"], ;
                                     "dEmi" => occ["dEmi"], ;
                                     "emiOcc" => {"CNPJ" => occ["CNPJ"], "IE" => occ["IE"], "UF" => occ["UF"]} ;
                                    })
                            endif
                        next
                    endif
                    */
                    infModal["rodo"] := rodo

                else
                    // Aéreo: Informação do modal Aéreo
                    aereo := {=>}
                    // nMinu omitido, Nuvem fiscal gera automático
                    // aereo["nMinu"] := ::cte:cCT

                    if !Empty(::cte:nOCA)
                        aereo["nOCA"] := ::cte:nOCA
                    endif
                    aereo["dPrevAereo"] := ::cte:dPrevAereo
                    aereo["natCarga"] := ::cte:aereo

                    tarifa := ::cte:comp_calc[1]
                    tpTar := Upper(desacentuar(tarifa["CL"]))
                    CL := Left(tpTar, 1)    // Testando, Nuvem fiscal fez as correções - Forçando tarifa Mínima, até descobrir pq a sefaz/nuvem fiscal só aceita M

                    if !(CL $ "MGE")
                        do case
                            case "MINIM" $ tpTar
                                CL := "M"
                            case "GERAL" $ tpTar
                                CL := "G"
                            case "ESPECIFIC" $ tpTar
                                CL := "E"
                            otherwise
                                CL := "G"
                        endcase
                    endif

                    aereo["tarifa"] := {"CL" => CL, ;
                                        "cTar" => ::cte:cTar, ;
                                        "vTar" => "$$" + LTrim(Transform(tarifa["vTar"], "9999999999.99")) + "$$"  ;
                                        }
                    infModal["aereo"] := aereo
                endif

                infCteNorm["infModal"] := infModal
                infModal := rodo := aereo := nil

                // veicNovos, cobr, infCteSub: Não utilizados
                if (::cte:indGlobalizado == 1)
                    infCteNorm["infGlobalizado"] := {"xObs" => "Procedimento efetuado conforme Resolução/SEFAZ n. 2.833/2017"}
                endif
            else
                // tpServ: 1 - Subcontratação; 2 – Redespacho; 3 – Redespacho Intermediário; 4 – Serviço Vinculado à Multimodal
                // infServVinc: Não utilizado
            endif
        endif
        infCte["infCTeNorm"] := infCteNorm
        infCteNorm := nil
    elseif (::cte:tpCTe == 1)
        // tp::cte: 1 - CT-e de Complemento de Valores
        // infCteComp: Não implementado
    else
      // 2 - CT-e de Anulação * Não implementado
      // infCteAnu | Detalhamento do CT-e do tipo Anulação
    endif

    if !Empty(::cte:autXML)
        infCte["autXML"] := ::cte:autXML
    endif

    if !Empty(RegistryRead(appData:winRegistryPath + "Host\respTec\CNPJ"))
        infCte["infRespTec"] := {"CNPJ" => RegistryRead(appData:winRegistryPath + "Host\respTec\CNPJ"), ;
                                 "xContato" => RegistryRead(appData:winRegistryPath + "Host\respTec\xContato"), ;
                                 "email" => RegistryRead(appData:winRegistryPath + "Host\respTec\email"), ;
                                 "fone" => RegistryRead(appData:winRegistryPath + "Host\respTec\fone")}
    endif

    // infSolicNFF: Não utilizado
    // infCteSupl: Gerado automaticamente pela nuvem fiscal

    // Cria o Body Hash Table
    hBody := {"infCte" => infCte, "ambiente" => ::ambiente, "referencia" => ::referencia_uuid}
    ::body := hb_jsonEncode(hBody, 4)
    ::body := StrTran(::body, '"$$')
    ::body := StrTran(::body, '$$"')

    // Debug
    // hb_MemoWrit("tmp\CTe" + hb_ntos(::cte:nCT) + ".json", ::body)

return nil

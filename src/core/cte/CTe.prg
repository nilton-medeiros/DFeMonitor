#include "hmg.ch"
#include "hbclass.ch"

#define TDZ_TRUE .T.

// Interface entre appp e DB ()
class TCTe

    data id readonly    // id do CTe no sistema TMS.Cloud
    data emp_id readonly
    data versao_xml readonly
    data dhEmi readonly
    data modelo readonly
    data serie readonly
    data nCT readonly
    data cCT readonly
    data situacao readonly
    data chCTe
    data nProt readonly
    data CFOP readonly
    data natOp readonly
    data tpEmis
    data dhCont
    data xJust
    data tpCTe readonly
    data indGlobalizado readonly
    data modal readonly
    data tpServ readonly
    data cMunIni readonly
    data xMunIni readonly
    data UFIni readonly
    data cMunFim readonly
    data xMunFim readonly
    data UFFim readonly
    data retira readonly
    data xDetRetira readonly
    data clie_tomador_id readonly
    data indIEToma readonly
    data tom_ie_isento readonly
    data tomador readonly
    data tom_cnpj readonly
    data tom_ie readonly
    data tom_cpf readonly
    data tom_xFant readonly
    data tom_xNome readonly
    data tom_fone readonly
    data tom_end_logradouro readonly
    data tom_end_numero readonly
    data tom_end_complemento readonly
    data tom_end_bairro readonly
    data tom_cid_codigo_municipio readonly
    data tom_cid_municipio readonly
    data tom_end_cep readonly
    data tom_cid_uf readonly
    data tom_email readonly
    data xCaracAd readonly
    data xCaracSer readonly
    data xEmi readonly
    data xOrig readonly
    data xPass readonly
    data xDest readonly
    data tpPer readonly
    data dProg readonly
    data dIni readonly
    data dFim readonly
    data tpHor readonly
    data hProg readonly
    data hIni readonly
    data hFim readonly
    data xObs readonly
    data clie_remetente_id readonly
    data rem_razao_social readonly
    data rem_nome_fantasia readonly
    data rem_cnpj readonly
    data rem_ie readonly
    data rem_cpf readonly
    data rem_fone readonly
    data rem_end_logradouro readonly
    data rem_end_numero readonly
    data rem_end_complemento readonly
    data rem_end_bairro readonly
    data rem_cid_codigo_municipio readonly
    data rem_cid_municipio readonly
    data rem_end_cep readonly
    data rem_cid_uf readonly
    // data rem_icms readonly   ** Não usado
    data rem_email readonly
    data clie_destinatario_id readonly
    data des_razao_social readonly
    data des_nome_fantasia readonly
    data des_cnpj readonly
    data des_ie readonly
    data des_cpf readonly
    data des_fone readonly
    data des_end_logradouro readonly
    data des_end_numero readonly
    data des_end_complemento readonly
    data des_end_bairro readonly
    data des_cid_codigo_municipio readonly
    data des_cid_municipio readonly
    data des_end_cep readonly
    data des_cid_uf readonly
    data des_icms readonly
    data des_ISUF readonly
    data des_email readonly
    data clie_expedidor_id readonly
    data exp_razao_social readonly
    data exp_nome_fantasia readonly
    data exp_cnpj readonly
    data exp_ie readonly
    data exp_cpf readonly
    data exp_fone readonly
    data exp_end_logradouro readonly
    data exp_end_numero readonly
    data exp_end_complemento readonly
    data exp_end_bairro readonly
    data exp_cid_codigo_municipio readonly
    data exp_cid_municipio readonly
    data exp_end_cep readonly
    data exp_cid_uf readonly
    // data exp_icms readonly  ** Não usado
    data exp_email readonly
    data clie_recebedor_id readonly
    data rec_razao_social readonly
    data rec_nome_fantasia readonly
    data rec_cnpj readonly
    data rec_ie readonly
    data rec_cpf readonly
    data rec_fone readonly
    data rec_end_logradouro readonly
    data rec_end_numero readonly
    data rec_end_complemento readonly
    data rec_end_bairro readonly
    data rec_cid_codigo_municipio readonly
    data rec_cid_municipio readonly
    data rec_end_cep readonly
    data rec_cid_uf readonly
    // data rec_icms readonly
    data rec_email readonly
    data vTPrest readonly
    data vBC readonly
    data pICMS readonly
    data vICMS readonly
    data pRedBC readonly
    data vCred readonly
    data codigo_sit_tributaria readonly
    data vTotTrib readonly
    data infAdFisco readonly
    data vCarga readonly
    data proPred readonly
    data cTar readonly
    data xOutCat readonly
    data peso_bruto readonly
    data peso_cubado readonly
    data peso_bc readonly
    data cubagem_m3 readonly
    data qtde_volumes readonly
    data tipo_doc_anexo readonly
    data doc_anexo readonly
    data nOCA readonly
    data dPrevAereo readonly
    data monitor_action readonly
    data referencia_uuid readonly
    data nuvemfiscal_uuid
    data obs_fisco readonly
    data obs_contr readonly
    data comp_calc readonly
    data emitente readonly
    data tpImp readonly
    data calc_difal readonly
    data cUF readonly
    data tpAmb readonly
    data docAnt readonly
    data rodoOcc readonly
    data aereo readonly
    data updateCTe readonly
    data updateEventos readonly
    data autXML readonly

    method new(cte, hAnexos, clie_emails, emiDocAnt, modalidade) constructor
    method infIndGlobalizado()
    method setSituacao(cteStatus)
    method setUpdateCte(key, value)
    method setUpdateEventos(cte_ev_protocolo, cte_ev_data_hora, cte_ev_evento, cte_ev_detalhe)
    method save()
    method saveEventos()

end class

method new(cte, hAnexos, clie_emails, emiDocAnt, modalidade) class TCTe
    local clie, obs, nValFCP, percDIFAL, valorDIFAL
    local REGISTRY_PATH, cCertDigExpiresIn, dCertDigExpiresIn, difDays
    // local msgLog

    ::id := cte["id"]
    ::emp_id := cte["emp_id"]
    ::versao_xml := hb_ntos(cte["versao_xml"])

    if (Len(Token(::versao_xml, ".")) == 1)
        ::versao_xml += "0"
    endif

    ::dhEmi := string_as_DateTime(cte["dhEmi"], TDZ_TRUE)
    ::modelo := number_format(cte["modelo"])
    ::serie := cte["serie"]
    ::nCT := cte["nCT"] // Numero do CTe
    ::cCT := PadL(cte["cCT"], 8, "0") // Numero da Minuta
    ::situacao := hmg_upper(cte["situacao"])
    ::chCTe := cte["chCTe"]
    ::nProt := cte["nProt"]
    ::CFOP := hb_ntos(cte["CFOP"])
    ::natOp := cte["natOp"]
    ::tpEmis := cte["tpEmis"]
    ::dhCont := ""
    ::xJust := ""
    ::tpCTe := cte["tpCTe"]

    if (cte["modal"] == 2)
        ::modal := "02" // Aereo
    elseif (cte["modal"] == 6)
        ::modal := "06" // Multimmodal
    else
        ::modal := "01" // Rodoviário
    endif

    ::tpServ := cte["tpServ"]
    ::cMunIni := hb_ntos(cte["cMunIni"])
    ::xMunIni := cte["xMunIni"]
    ::UFIni := cte["UFIni"]
    ::cMunFim := hb_ntos(cte["cMunFim"])
    ::xMunFim := cte["xMunFim"]
    ::UFFim := cte["UFFim"]
    ::retira := cte["retira"]
    ::xDetRetira := cte["xDetRetira"]
    ::clie_tomador_id := cte["clie_tomador_id"]
    ::tom_ie_isento := cte["tom_ie_isento"]

    if cte["indIEToma"] == 0        // 0 = false
        ::indIEToma := 9            // Não Contribuinte. Aplica-se ao tomador que for indicado no toma3 ou toma4
    elseif ::tom_ie_isento == 1     // 1 = true
        ::indIEToma := 2            // Contribuinte isento de inscrição
    else
        ::indIEToma := 1            // Contribuinte de ICMS
    endif

    ::tomador := cte["tomador"]
    ::tom_cnpj := getNumbers(cte["tom_cnpj"])
    ::tom_ie := cte["tom_ie"]
    ::tom_cpf := getNumbers(cte["tom_cpf"])
    ::tom_xFant := cte["tom_xFant"]
    ::tom_xNome := cte["tom_xNome"]
    ::tom_fone := getNumbers(cte["tom_fone"])
    ::tom_end_logradouro := cte["tom_end_logradouro"]
    ::tom_end_numero := cte["tom_end_numero"]
    ::tom_end_complemento := cte["tom_end_complemento"]
    ::tom_end_bairro := cte["tom_end_bairro"]
    ::tom_cid_codigo_municipio := hb_ntos(cte["tom_cid_codigo_municipio"])
    ::tom_cid_municipio := cte["tom_cid_municipio"]
    ::tom_end_cep := getNumbers(cte["tom_end_cep"])
    ::tom_cid_uf := cte["tom_cid_uf"]
    ::xCaracAd := cte["xCaracAd"]
    ::xCaracSer := cte["xCaracSer"]
    ::xEmi := cte["xEmi"]
    ::xOrig := cte["xOrig"]
    ::xPass := iif(Empty(cte["xPass"]), "OACI", cte["xPass"])
    ::xDest := cte["xDest"]
    ::tpPer := cte["tpPer"]
    ::dProg := cte["dProg"]
    ::dIni := cte["dIni"]
    ::dFim := cte["dFim"]
    ::tpHor := cte["tpHor"]
    ::hProg := cte["hProg"]
    ::hIni := cte["hIni"]
    ::hFim := cte["hFim"]
    ::xObs := StrTran(StrTran(cte["xObs"], "\n", " | "), hb_eol(), " | ")
    ::xObs := desacentuar(::xObs)
    ::clie_remetente_id := cte["clie_remetente_id"]
    ::rem_razao_social := cte["rem_razao_social"]
    ::rem_nome_fantasia := cte["rem_nome_fantasia"]
    ::rem_cnpj := getNumbers(cte["rem_cnpj"])
    ::rem_ie := cte["rem_ie"]
    ::rem_cpf := getNumbers(cte["rem_cpf"])
    ::rem_fone := getNumbers(cte["rem_fone"])
    ::rem_end_logradouro := cte["rem_end_logradouro"]
    ::rem_end_numero := cte["rem_end_numero"]
    ::rem_end_complemento := cte["rem_end_complemento"]
    ::rem_end_bairro := cte["rem_end_bairro"]
    ::rem_cid_codigo_municipio := hb_ntos(cte["rem_cid_codigo_municipio"])
    ::rem_cid_municipio := cte["rem_cid_municipio"]
    ::rem_end_cep := getNumbers(cte["rem_end_cep"])
    ::rem_cid_uf := cte["rem_cid_uf"]
    // ::rem_icms := cte["rem_icms"]   ** Não usado
    ::clie_destinatario_id := cte["clie_destinatario_id"]
    ::des_razao_social := cte["des_razao_social"]
    ::des_nome_fantasia := cte["des_nome_fantasia"]
    ::des_cnpj := getNumbers(cte["des_cnpj"])
    ::des_ie := cte["des_ie"]
    ::des_cpf := getNumbers(cte["des_cpf"])
    ::des_fone := getNumbers(cte["des_fone"])
    ::des_end_logradouro := cte["des_end_logradouro"]
    ::des_end_numero := cte["des_end_numero"]
    ::des_end_complemento := cte["des_end_complemento"]
    ::des_end_bairro := cte["des_end_bairro"]
    ::des_cid_codigo_municipio := hb_ntos(cte["des_cid_codigo_municipio"])
    ::des_cid_municipio := cte["des_cid_municipio"]
    ::des_end_cep := getNumbers(cte["des_end_cep"])
    ::des_cid_uf := cte["des_cid_uf"]
    ::des_icms := cte["des_icms"]
    ::des_ISUF := cte["des_inscricao_suframa"]
    ::clie_expedidor_id := cte["clie_expedidor_id"]
    ::exp_razao_social := cte["exp_razao_social"]
    ::exp_nome_fantasia := cte["exp_nome_fantasia"]
    ::exp_cnpj := getNumbers(cte["exp_cnpj"])
    ::exp_ie := cte["exp_ie"]
    ::exp_cpf := getNumbers(cte["exp_cpf"])
    ::exp_fone := getNumbers(cte["exp_fone"])
    ::exp_end_logradouro := cte["exp_end_logradouro"]
    ::exp_end_numero := cte["exp_end_numero"]
    ::exp_end_complemento := cte["exp_end_complemento"]
    ::exp_end_bairro := cte["exp_end_bairro"]
    ::exp_cid_codigo_municipio := hb_ntos(cte["exp_cid_codigo_municipio"])
    ::exp_cid_municipio := cte["exp_cid_municipio"]
    ::exp_end_cep := getNumbers(cte["exp_end_cep"])
    ::exp_cid_uf := cte["exp_cid_uf"]
    // ::exp_icms := cte["exp_icms"]  ** Não usado
    ::clie_recebedor_id := cte["clie_recebedor_id"]
    ::rec_razao_social := cte["rec_razao_social"]
    ::rec_nome_fantasia := cte["rec_nome_fantasia"]
    ::rec_cnpj := getNumbers(cte["rec_cnpj"])
    ::rec_ie := cte["rec_ie"]
    ::rec_cpf := getNumbers(cte["rec_cpf"])
    ::rec_fone := getNumbers(cte["rec_fone"])
    ::rec_end_logradouro := cte["rec_end_logradouro"]
    ::rec_end_numero := cte["rec_end_numero"]
    ::rec_end_complemento := cte["rec_end_complemento"]
    ::rec_end_bairro := cte["rec_end_bairro"]
    ::rec_cid_codigo_municipio := hb_ntos(cte["rec_cid_codigo_municipio"])
    ::rec_cid_municipio := cte["rec_cid_municipio"]
    ::rec_end_cep := getNumbers(cte["rec_end_cep"])
    ::rec_cid_uf := cte["rec_cid_uf"]
    // ::rec_icms := cte["rec_icms"]
    ::vTPrest := cte["vTPrest"]
    ::vBC := cte["vBC"]
    ::pICMS := cte["pICMS"]
    ::vICMS := cte["vICMS"]
    ::pRedBC := cte["pRedBC"]
    ::vCred := cte["vCred"]
    ::codigo_sit_tributaria := cte["codigo_sit_tributaria"]
    ::vTotTrib := cte["vTotTrib"]
    ::infAdFisco := cte["infAdFisco"]
    ::vCarga := number_format(cte["vCarga"], 2)
    ::proPred := cte["proPred"]
    ::cTar := hb_ntos(cte["cTar"])
    ::xOutCat := cte["xOutCat"]
    ::peso_bruto := cte["peso_bruto"]
    ::peso_cubado := cte["peso_cubado"]
    ::peso_bc := cte["peso_bc"]
    ::cubagem_m3 := cte["cubagem_m3"]
    ::qtde_volumes := cte["qtde_volumes"]
    ::tipo_doc_anexo := cte["tipo_doc_anexo"]
    ::nOCA := cte["nOCA"]
    ::dPrevAereo := cte["dPrevAereo"]
    ::referencia_uuid := cte["referencia_uuid"]
    ::nuvemfiscal_uuid := cte["nuvemfiscal_uuid"]
    ::monitor_action := cte["monitor_action"]
    ::updateCte := {}
    ::updateEventos := {}
    ::indGlobalizado := 0
    ::emitente := appEmpresas:getEmpresa(::emp_id)
    ::tpImp := ::emitente:tpImp
    ::cUF := ::emitente:cUF
    ::tpAmb := ::emitente:tpAmb
    ::obs_contr := {}
    ::obs_fisco := {}
    ::autXML := {}

    // Obrigatoriedade CNPJ ANTT - Tag autXML | CT-e/MDF-e
    // Adiciona o CNPJ da ANTT na tag autXML, artigo 22 da  Resolução ANTT nº 4.799/2015
    AAdd(::autXML, {"CNPJ" => "04898488000177"})

    // Incluir o CNPJ da Contabilidade se houver
    if !Empty(::emitente:cnpj_contabil)
        AAdd(::autXML, {"CNPJ" => ::emitente:cnpj_contabil})
    endif

    REGISTRY_PATH := appData:winRegistryPath + "nuvemFiscal\Emp" + hb_ntos(::id) + "\"
    cCertDigExpiresIn := RegistryRead(REGISTRY_PATH + "certificado\expires_in")

    if (ValType(cCertDigExpiresIn) == "C")
        // "yyyy-mm-dd HH:mm:ss"
        dCertDigExpiresIn := hb_CToT(cCertDigExpiresIn)
        difDays := int(dCertDigExpiresIn - hb_DateTime())
        if (difDays < 11)
            // Poe aviso na DACTE para alertar emissor que o certificado vai expirar
            ::xEmi += " | CERTIFICADO EXPIRA EM " + cCertDigExpiresIn
        endif
    endif

    // Adiciona o Emissor à tag ObsCont "Uso Exclusivo do Emissor de CT-e"
    AAdd(::obs_contr, {"xCampo" => "Emissor", "xTexto" => ::xEmi})

    // Docs anexos ao CTe
    for each obs in hAnexos["obs_fisco"]
        if (obs["interessado"] == "CONTRIBUINTE")
            AAdd(::obs_contr, {"xCampo" => Left(obs["xCampo"], 20), "xTexto" => obs["xTexto"]})
        else
            AAdd(::obs_fisco, {"xCampo" => Left(obs["xCampo"], 20), "xTexto" => obs["xTexto"]})
        endif
    next

    if !Empty(::vTotTrib)
        // msgLog := MsgDebug(Valtype(::vICMS), ::vICMS, Valtype(::vTotTrib), ::vTotTrib)
        AAdd(::obs_contr, {"xCampo" => "LEI DA TRANSPARENCIA",;
                           "xTexto" => "12741/12 O valor aproximado de tributos incidentes sobre o preco deste servico e de R$ " + ;
                            LTrim(Transform(::vTotTrib, "@E 99,999,999.99"))})
                            // " ICMS " + hb_ntos(::vICMS) +;
    endif

    ::comp_calc := hAnexos['comp_calc']
    ::doc_anexo := hAnexos['doc']

    ::infIndGlobalizado()

    if (::indGlobalizado == 1)
        ::xObs := iif(Empty(::xObs), "", ::xObs + " | ") + "Procedimento efetuado conforme Resolução/SEFAZ n. 2.833/2017"
    endif

    for each clie in clie_emails
        switch clie["name"]
            case "tomador"
                ::tom_email := AllTrim(clie['email'])
                exit
            case "remetente"
                ::rem_email := AllTrim(clie['email'])
                exit
            case "destinatario"
                ::des_email := AllTrim(clie['email'])
                exit
            case "expedidor"
                ::exp_email := AllTrim(clie['email'])
                exit
            case "recebedor"
                ::rec_email := AllTrim(clie['email'])
                exit
        endswitch
    next

    ::calc_difal := {=>}

    // Informações do ICMS de partilha com a UF de término do serviço de transporte na operação interestadual
    if (hb_ntos(::tpCTe) $ '013') .and.;         // Tipo de CTe (tpCTe) = 0-Normal, 1-Complemento de Valores, 3-Substituto
        !(::UFIni == ::UFFim) .and.;   // e UF de término do serviço de transporte na operação interestadual
        (::tpServ == 0) .and.; // e Tipo de Serviço = 0-Normal
        (::des_icms == 0) .and.; // e consumidor (destinatário) não contribuinte do ICMS
        (::tomador == 3) .and.; // Tomador tem que ser o DESTINATÁRIO
        !(::codigo_sit_tributaria == "SIMPLES NACIONAL") // O STF decidiu que essa cobrança do ICMS do Diferencial de Alíquota – DIFAL, para empresas Optantes pelo Simples é inconstitucional, pois seu recolhimento foi previsto pela Lei Complementar n° 123, de 14 de dezembro de 2006, e seu recolhimento é feito pela guia unificada do Simples Nacional – DAS

        saveLog("DIFAL CALCULADO")

        // DIFAL - Diferença de Alíquota | FCP - Fundo de Combate a Pobreza | Arquivo SeFaz: CTe_Nota_Tecnica_2015_004.pdf (Pagina 4)
        if (::UFFim $ "AC|AL|AM|BA|CE|DF|ES|GO|MA|MG|MS|MT|PB|PE|PI|PR|RJ|RN|RO|RR|RS|SE|SP|TO")
            dbIcms := TDbIcms():new(::UFIni, ::UFFim)
            if (dbIcms:count == 2)
                ::calc_difal := {'pFCPUFFim' => 0.00, 'pICMSUFFim' => 0.00, 'pICMSInter' => 0.00, 'vFCPUFFim' => 0.00, 'vICMSUFFim' => 0.00, 'vICMSUFIni' => 0.00, 'pDIFAL' => 0, 'vDIFAL' => 0}
                nValFCP := ::vTPrest * 0.02
                ::calc_difal["pFCPUFFim"] := 2.00
                ::calc_difal["vFCPUFFim"] := nValFCP
                ::calc_difal["pICMSInter"] := dbIcms:pIni
                ::calc_difal["pICMSUFFim"] := dbIcms:pFim
                if (dbIcms:pFim > dbIcms:pIni)
                    percDIFAL := dbIcms:pFim - dbIcms:pIni
                    valorDIFAL := ::vTPrest * (percDIFAL/100)
                    ::calc_difal["pDIFAL"] := percDIFAL
                    ::calc_difal["vDIFAL"] := valorDIFAL
                    ::calc_difal["vICMSUFFim"] := valorDIFAL + nValFCP
                endif
            endif
        endif
    endif

    ::docAnt := {=>}
    if !Empty(emiDocAnt)
        ::docAnt["emiDocAnt"] := emiDocAnt
    endif

    if (::modal == "01")
        ::rodoOcc := modalidade
    else
        ::aereo := modalidade
    endif

return self

method infIndGlobalizado() class TCTe
    local nfe, cnpj, rem := {}, des := {}, docs := 0

    if (::tipo_doc_anexo == 2)
        // NFe
        docs := hmg_len(::doc_anexo)
    endif

    ::indGlobalizado := 0

    if (::tpCTe == 0) .and. (::tpServ == 0) .and. (docs > 4) .and. (::UFIni == ::UFFim)

        for each nfe in ::doc_anexo
            cnpj := hb_USubStr(nfe['chave'], 7, 14)
            if (cnpj == ::rem_cnpj) .and. (hb_AScan(rem, cnpj,,, true) == 0)
                AAdd(rem, cnpj)
            elseif (cnpj == ::des_cnpj) .and. (hb_AScan(des, cnpj,,, true) == 0)
                AAdd(des, cnpj)
            endif
        next

        if ((::tomador == 3) .and. (hmg_len(rem) > 4)) .or. ((::tomador == 0) .and. (hmg_len(rem) == 1) .and. ::des_razao_social == 'DIVERSOS' .and. (::des_cnpj == ::emitente:CNPJ))
            // Tomador: 3 - Destinatário, o número de CNPJ diferentes nas chaves emitidas pelos Remententes são maior ou igual a 5 ou
            // Tomador: 0 - Remetente, tem mais de 4 NFes (docs > 4), todas as NFes são do mesmo emitente (remetente) e tem vários destinatários
            ::indGlobalizado := 1
        endif

    endif

return nil

method setSituacao(cteStatus) class TCTe
    local lSet := false
    cteStatus := hmg_lower(cteStatus)
    if !Empty(cteStatus) .and. cteStatus $ "pendente,autorizado,rejeitado,denegado,encerrado,cancelado,erro"
        ::situacao := hmg_upper(cteStatus)
        lSet := true
        ::setUpdateCte("cte_situacao", ::situacao)
    else
        saveLog({"Status do CTe " + hb_ntos(::id) + " inválido", "Status: " + cteStatus}, "Warning")
    endif
return lSet

method setUpdateCte(key, value) class TCTe
    local lSet := false, pos

    if !Empty(key)
        pos := hb_ASCan(::updateCTe, {|hField| hField["key"] == key})
        if (pos == 0)
            AAdd(::updateCTe, {"key" => key, "value" => value})
        else
            ::updateCTe[pos]["value"] := value
        endif
        lSet := true
    endif

return lSet

method setUpdateEventos(cte_ev_protocolo, cte_ev_data_hora, cte_ev_evento, cte_ev_detalhe) class TCTe
    local ambiente := iif((::tpAmb == 1), "Produção", "Homologação")
    AAdd(::updateEventos, {"cte_id" => hb_ntos(::id), ;
                           "cte_ev_protocolo" => cte_ev_protocolo, ;
                           "cte_ev_data_hora" => cte_ev_data_hora, ;
                           "cte_ev_evento" => cte_ev_evento, ;
                           "cte_ev_detalhe" => cte_ev_detalhe + " | Ambiente: " + ambiente + " | DFeMonitor: " + appData:version})
return nil

method save() class TCTe
    local cte, ok := false
    if !Empty(::updateCTe)
        cte := TDbCTes():new()
        if (ok := cte:updateCTe(hb_ntos(::id), ::updateCTe))
            ::updateCTe := {}
        endif
    endif
return ok

method saveEventos() class TCTe
    local cte, ok := false
    local REGISTRY_PATH := appData:winRegistryPath + "nuvemFiscal\Emp" + hb_ntos(::id) + "\"
    local cCertDigExpiresIn := RegistryRead(REGISTRY_PATH + "certificado\expires_in")
    local dCertDigExpiresIn
    local difDays, msg := 'Certificado Digital '

    if !Empty(::updateEventos)

        if (ValType(cCertDigExpiresIn) == "C")
            // "yyyy-mm-dd HH:mm:ss"
            dCertDigExpiresIn := hb_CToT(cCertDigExpiresIn)
            difDays := (dCertDigExpiresIn - hb_DateTime())

            if (difDays < 16)
                // Registra nos eventos do CTE a validade do Certificado Digital
                if (difDays = 0)
                    msg += 'Expirou hoje '
                elseif (difDays < 0)
                    msg += 'Expirou em '
                elseif (int(difDays) == 0) .and. (difDays > 0)
                    msg += 'Expira hoje '
                else
                    msg += 'Expira em '
                endif
                msg += cCertDigExpiresIn

                AAdd(::updateEventos, {"cte_id" => hb_ntos(::id), ;
                    "cte_ev_protocolo" => 'CERT. DIGITAL', ;
                    "cte_ev_data_hora" => date_as_DateTime(Date(), false, false), ;
                    "cte_ev_evento" => 'Cert', ;
                    "cte_ev_detalhe" => msg + " | DFeMonitor: " + appData:version})
            endif

        endif

        cte := TDbCTes():new()
        if (ok := cte:insertEventos(::updateEventos))
            ::updateEventos := {}
        endif
    endif
return ok

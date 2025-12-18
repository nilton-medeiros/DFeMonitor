#include "hmg.ch"
#include "hbclass.ch"

class TMDFe
    data versao
    data sigla_cia
    data id         // id do MDFe no sistema TMS.Cloud
    data emp_id
    data emitente
    data tpAmb
    data ambiente
    data tpEmit
    data mod
    data serie
    data nMDF
    data cMDF
    data chMDFe
    data modal
    data nProt
    data dhEmi
    data tpEmis
    data procEmi
    data verProc
    data UFIni
    data UFFim
    data infMunCarrega
    data infPercurso
    data infContratante
    data veicTracao
    data condutor
    data infDescarga
    data aVerb
    data prodPred
    data autXML
    data frete
    data qCTe
    data vCarga
    data cUnid
    data qCarga
    data infAdFisco
    data infCpl
    data situacao
    data monitor_action
    data referencia_uuid
    data nuvemfiscal_uuid
    data updateMDFe
    data aUpdateEvents

    method new(hMDFe) constructor
    method setSituacao(mdfeStatus)
    method setUpdateMDFe(key, value)
    method setUpdateEventos(hEvent)
    method save()
    method saveEventos()

end class

method new(hMDFe) class TMDFe
    local mdfe := hMDFe["hDbMDFe"]

    ::id := mdfe["id"]
    ::sigla_cia := mdfe["sigla_cia"]
    ::emp_id := mdfe["emp_id"]
    ::emitente := appEmpresas:getEmpresa(::emp_id)
    ::versao := ::emitente:mdfe_versao_xml
    ::tpAmb := ::emitente:tpAmb
    ::ambiente := iif(::tpAmb == 1, "producao", "homologacao")
    ::tpEmit := mdfe["tpEmit"]
    ::mod := mdfe["modelo"]         // Modelo do MDFe
    ::serie := mdfe["serie"]
    ::nMDF := mdfe["nMDF"]
    ::cMDF := PadL(mdfe["id"], 8, "0")            // Código (id) que compõe a chave do MDFe
    ::chMDFe := mdfe["chMDFe"]      // Chave do MDFe
    ::modal := 1                    // MDFe sempre é = 1: Rodoviário
    ::dhEmi := mdfe["dhEmi"]
    ::tpEmis := mdfe["tpEmis"]
    ::procEmi := "0"                  // 0-Emissão de MDF-e com aplicativo do contribuinte
    ::verProc := mdfe["verProc"]
    ::UFIni := mdfe["UFIni"]
    ::UFFim := mdfe["UFFim"]
    ::infMunCarrega := hMDFe["carregamento"]
    ::infPercurso := hMDFe["percursos"]
    ::infContratante := hMDFe["contratantes"]
    ::veicTracao := hMDFe["veicTracao"]
    ::condutor := hMDFe["condutor"]
    ::infDescarga := hMDFe["infDescarga"]
    ::aVerb := hMDFe["aVerb"]
    ::prodPred := hMDFe["prodPred"]
    ::autXML := hMDFe["autXML"]
    ::frete := hb_HGetDef(hMDFe, "frete", 0)

    // Obrigatoriedade CNPJ ANTT - Tag autXML | MDF-e
    // Adiciona o CNPJ da ANTT na tag autXML, artigo 22 da  Resolução ANTT nº 4.799/2015
    AAdd(::autXML, {"CNPJ" => "04898488000177"})

    // Incluir o CNPJ da Contabilidade se houver
    if !Empty(::emitente:cnpj_contabil)
        AAdd(::autXML, {"CNPJ" => ::emitente:cnpj_contabil})
    endif

    ::qCTe := mdfe["qCTe"]
    ::vCarga := mdfe["vCarga"]
    ::cUnid := PadL(mdfe["cUnid"], 2, "0")
    ::qCarga := mdfe["qCarga"]
    ::infAdFisco := mdfe["infAdFisco"]
    ::infCpl := mdfe["infCpl"]
    ::situacao := mdfe["situacao"]
    ::monitor_action := mdfe["monitor_action"]
    ::nProt := mdfe["nProt"]
    ::referencia_uuid := mdfe["referencia_uuid"]
    ::nuvemfiscal_uuid := mdfe["nuvemfiscal_uuid"]
    ::updateMDFe := {}
    ::aUpdateEvents := {}

return self

method setSituacao(mdfeStatus) class TMDFe
    local lSet := false
    mdfeStatus := hmg_lower(mdfeStatus)
    if !Empty(mdfeStatus) .and. mdfeStatus $ "pendente|autorizado|rejeitado|denegado|encerrado|cancelado|erro"
        ::situacao := hmg_upper(mdfeStatus)
        lSet := true
        ::setUpdateMDFe("situacao", ::situacao)
    else
        saveLog({"Status do MDFe id " + hb_ntos(::id) + " invalido", "Status: " + mdfeStatus}, "Warning")
    endif
return lSet

method setUpdateMDFe(key, value) class TMDFe
    local lSet := false, pos

    if !Empty(key)
        pos := hb_ASCan(::updateMDFe, {|hField| hField["key"] == key})
        if (pos == 0)
            AAdd(::updateMDFe, {"key" => key, "value" => value})
        else
            ::updateMDFe[pos]["value"] := value
        endif
        lSet := true
    endif

return lSet

method setUpdateEventos(hEvent) class TMDFe
    local event_id := hb_HGetDef(hEvent, 'event_id', "")
    local ambiente := hb_HGetDef(hEvent, 'ambiente', ::ambiente)
    local status_evento := hb_HGetDef(hEvent, 'status_evento', "registrado")
    local chave_acesso := hb_HGetDef(hEvent, 'chave_acesso', "")
    local data_evento := hb_HGetDef(hEvent, 'data_evento', "")
    local data_recebimento := hb_HGetDef(hEvent, 'data_recebimento', "")
    local data_encerramento := hb_HgetDef(hEvent, 'data_encerramento', "")
    local codigo_status := hb_HGetDef(hEvent, 'codigo_status', 0)
    local motivo := hb_HGetDef(hEvent, 'motivo_status', "NAO INFORMADO")
    local motivo_status := hb_HGetDef(hEvent, 'motivo_status', "")
    local detalhe := hb_HGetDef(hEvent, 'detalhe', motivo)
    local evento := "---"
    local protocolo := hb_HGetDef(hEvent, 'numero_protocolo', "---")
    local data_hora := hb_HGetDef(hEvent, 'data_hora', iif(Empty(data_evento), date_as_DateTime(Date(), false, false), data_evento))
    local numero_protocolo := hb_HGetDef(hEvent, 'numero_protocolo', "")
    local tipo_evento := hb_HGetDef(hEvent, 'tipo_evento', "")
    local justificativa := hb_HGetDef(hEvent, 'justificativa', "")
    local digest_value := hb_HGetDef(hEvent, 'digest_value', "")

    // Se for uma string numérica (ex:"123") válido, converte em número ou 0 se não for válido
    if (ValType(codigo_status) == "C")
        codigo_status := val(codigo_status)
    endif
    if !(ValType(codigo_status) == "N")
        codigo_status := 0
    endif

    // No SQL o número é passado para string
    if Empty(codigo_status)
        codigo_status := ""  // Será atribuido NULL no SQL
    else
        codigo_status := hb_ntos(codigo_status)
        evento := codigo_status
    endif

    if !Empty(data_encerramento)
        detalhe := "Data encerramento: " + data_encerramento + " | " + detalhe
    endif

    AAdd(::aUpdateEvents, ;
        { ;
            "mdfe_id" => hb_ntos(::id), ;
            "protocolo" => protocolo, ;
            "data_hora" => data_hora, ;
            "evento" => evento, ;
            "motivo" => motivo, ;
            "detalhe" => detalhe + " | DFeMonitor: " + appData:version, ;
            "event_id" => event_id, ;
            "ambiente" => ambiente, ;
            "status_evento" => status_evento, ;
            "chave_acesso" => chave_acesso, ;
            "data_evento" => data_evento, ;
            "data_recebimento" => data_recebimento, ;
            "data_encerramento" => data_encerramento, ;
            "codigo_status" => codigo_status, ;
            "motivo_status" => motivo_status, ;
            "numero_protocolo" => numero_protocolo, ;
            "tipo_evento" => tipo_evento, ;
            "justificativa" => justificativa, ;
            "digest_value" => digest_value ;
        } ;
    )

return nil

method save() class TMDFe
    local db
    if !Empty(::updateMDFe)
        db := TDbMDFes():new()
        if db:updateMDFe(hb_ntos(::id), ::updateMDFe)
            ::updateMDFe := {}
        endif
    endif
return nil

method saveEventos() class TMDFe
    local db
    if !Empty(::aUpdateEvents)
        db := TDbMDFes():new()
        if db:insertEventos(::aUpdateEvents)
            ::aUpdateEvents := {}
        endif
    endif
return nil

#include "hmg.ch"
#include "hbclass.ch"

class TMDFe
    data versao
    data id         // id do MDFe no sistema TMS.Cloud
    data emp_id
    data emitente
    data tpAmb
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
    data updateEvents

    method new(hMDFe) constructor
    method setSituacao(mdfeStatus)
    method setUpdateMDFe(key, value)
    method setUpdateEventos(protocolo, data_hora, evento, detalhe)
    method save()
    method saveEventos()

end class

method new(hMDFe) class TMDFe
    local mdfe := hMDFe["hDbMDFe"]

    ::id := mdfe["id"]
    ::emp_id := mdfe["emp_id"]
    ::emitente := appEmpresas:getEmpresa(::emp_id)
    ::versao := ::emitente:mdfe_versao_xml
    ::tpAmb := ::emitente:tpAmb
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
    ::updateEvents := {}

return self

method setSituacao(mdfeStatus) class TMDFe
    local lSet := false
    mdfeStatus := hmg_lower(mdfeStatus)
    if !Empty(mdfeStatus) .and. mdfeStatus $ "pendente,autorizado,rejeitado,denegado,encerrado,cancelado,erro"
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

method setUpdateEventos(protocolo, data_hora, evento, detalhe) class TMDFe
    local ambiente := iif((::tpAmb == 1), "Produção", "Homologação")
    AAdd(::updateEvents, {"mdfe_id" => hb_ntos(::id), ;
                           "protocolo" => protocolo, ;
                           "data_hora" => data_hora, ;
                           "evento" => evento, ;
                           "motivo" => "Ambiente: " + ambiente, ;
                           "detalhe" => detalhe + " | DFeMonitor: " + appData:version})
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
    if !Empty(::updateEvents)
        db := TDbMDFes():new()
        if db:insertEventos(::updateEvents)
            ::updateEvents := {}
        endif
    endif
return nil

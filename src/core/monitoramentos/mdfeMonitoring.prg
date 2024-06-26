#include "hmg.ch"

procedure mdfeMonitoring()
    local idAnterior := -1, log := {=>}
    local mdfe, dbMDFes := TDbMDFes():new()

    dbMDFes:getListMDFes()

    if (dbMDFes:count == 0)
        return // Não retornou MDFEs para transmitir a Sefaz
    endif

    for each mdfe in dbMDFes:mdfes

        if (idAnterior == mdfe:id)
            if !Empty(mdfe:sql)
                log["mdfe_id"] := mdfe:id
                log["referencia_uid"] := mdfe:referencia_uuid
                log["msg"] := "MDFe em duplicidade em getListMDFes()"
                log["query"] := mdfe:sql
                saveLog(log)
            endif
            loop
        endif

        idAnterior := mdfe:id

        if Empty(mdfe:nuvemfiscal_uuid)
            mdfeSubmit(mdfe)
        else
            switch mdfe:monitor_action
                case "GETFILES"     // Obter arquivos PDF & XML
                    mdfeGetFiles(TApiMDFe():new(mdfe))
                    exit
                case "CANCEL"       // Cancelar
                    mdfeCancel(mdfe)
                    exit
                case "CLOSE"        // Encerrar
                    mdfeClose(mdfe)
                    exit
                case "CONSULT"
                    mdfeConsult(mdfe)
                    exit
                case "SUBMIT"       // Consultar, pois já existe o id na nuvem fiscal
                    if (mdfe:situacao == "REJEITADO")
                        mdfeSubmit(mdfe)
                    else
                        mdfeConsult(mdfe)
                    endif
                    exit
                endswitch
        endif
        // cte_monitor_action: Mesmo nome de campo nas tabelas ctes e mdfes
        mdfe:setUpdateMDFe('cte_monitor_action', "EXECUTED")
        mdfe:save()
        mdfe:saveEventos()
        DO EVENTS
    next

return
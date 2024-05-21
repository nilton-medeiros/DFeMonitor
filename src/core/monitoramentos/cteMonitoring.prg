#include "hmg.ch"

procedure cteMonitoring()
    local idAnterior := -1, log := {=>}
    local cte, dbCTes := TDbCTes():new()

    dbCTes:getListCTes()

    if (dbCTes:count == 0)
        return // Não retornou CTEs para transmitir a Sefaz
    endif

    for each cte in dbCTes:ctes

        if (idAnterior == cte:id)
            if !Empty(cte:sql)
                log["cte_id"] := cte:id
                log["referencia_uid"] := cte:referencia_uuid
                log["msg"] := "CTe em duplicidade em getListCTes()"
                log["query"] := cte:sql
                saveLog(log)
            endif
            loop
        endif

        idAnterior := cte:id

        if Empty(cte:nuvemfiscal_uuid)
            cteSubmit(cte)
        else
            switch cte:monitor_action
                case "GETFILES"
                    cteGetFiles(TApiCTe():new(cte))
                    exit
                case "CANCEL"
                    cteCancel(cte)
                    exit
                case "CONSULT"
                    cteConsult(cte)
                    exit
                case "SUBMIT"   // Consultar, pois já existe o id da nuvem fiscal
                    if (Upper(cte:situacao) == "REJEITADO")
                        cteSubmit(cte)  // Tem nuvemfiscal_uuid, mas foi rejeitado anteriormente, submete novamente para autorizar
                    else
                        cteConsult(cte)
                    endif
                    exit
            endswitch
        endif

        cte:setUpdateCte('cte_monitor_action', "EXECUTED")
        cte:save()
        cte:saveEventos()
        DO EVENTS

    next

return
#include "hmg.ch"
#include <hbclass.ch>

class TQuery

    data db as object readonly
    data sql readonly
    data executed readonly
    data count readonly

    method new(cSql) constructor
    method runQuery(sql)
    method serverBusy()
    method Skip() inline ::db:Skip()
    method GoTop() inline ::db:GoTop()
    method GetRow() inline ::db:GetRow()
    method eof() inline ::db:eof()
    method FieldGet(cnField) inline ::db:FieldGet(cnField)
    method Destroy()

end class

method new(cSql) class TQuery
    local aLog := {}

    ::sql := cSql
    ::executed := false
    ::count := 0

    if appDataSource:connected .or. appDataSource:connect()
        SetProperty("main", "NotifyIcon", "serverWAIT")
        msgNotify({'notifyTooltip' => "Executando query..."})
        if ::runQuery()
            ::count := ::db:LastRec()
            ::db:GoTop()
            msgNotify()
            SetProperty("main", "NotifyIcon", "serverON")
        elseif ("lost connection" $ hmg_lower(::db:Error()))
            AAdd(aLog, "Conexão perdida com banco de dados. Reconectando...")
            if appDataSource:connect()
                AAdd(aLog, "Conexão Restabelecida!")
                if ::runQuery()
                    ::count := ::db:LastRec()
                    ::db:GoTop()
                    msgNotify()
                    AAdd(aLog, "Query executada com sucesso!")
                    SetProperty("main", "NotifyIcon", "serverON")
                else
                    AAdd(aLog, "Erro na execução da Query!")
                    msgNotify({"notifyTooltip" => "B.D. não conectado!"})
                    SetProperty("main", "NotifyIcon", "serverOFF")
                endif
            else
                AAdd(aLog, "Conexão perdida, query não executada!")
            endif
            saveLog(aLog, "Warning")
        else
            msgNotify({"notifyTooltip" => "B.D. não conectado!"})
            saveLog("Banco de Dados não conectado!", "Warning")
            SetProperty("main", "NotifyIcon", "serverOFF")
        endif
    endif

return self

method runQuery() class TQuery
    local tenta as numeric
    local command, table, mode

    ::executed := false
    ::db := appDataSource:mysql:Query(::sql)

    if (::db == nil)
        if !appDataSource:connect()
            msgNotify({"notifyTooltip" => "B.D. não conectado!"})
            saveLog("Banco de Dados não conectado!", "Warning")
            return false
        endif
        ::db := appDataSource:mysql:Query(::sql)
        if (::db == nil)
            msgNotify({'notifyTooltip' => "Erro de SQL!"})
            saveLog("Erro ao executar Query! [Query is NIL]", "Error")
            msgDebugInfo({'Erro ao executar ::db, avise ao suporte!', hb_eol() + hb_eol(), 'Ver Log do sistema', hb_eol(), 'Erro: Query is NIL'})
            return false
        endif
    endif

    command := hmg_upper(firstString(hb_utf8StrTran(::db:cQuery, ";")))
    command := AllTrim(command)

    do case
        case command $ "SELECT|DELETE"
            table := hb_USubStr(::db:cQuery, hb_UAt(' FROM ', ::db:cQuery))
            table := firstString(hb_USubStr(table, 7))
            mode := iif(command == "SELECT", "selecionar", "excluir")
        case command == "INSERT"
            table := hb_USubStr(::db:cQuery, hb_UAt(" INTO ", ::db:cQuery))
            table := firstString(hb_USubStr(table, 7))
            mode := "incluir"
        case command == "UPDATE"
            table := hb_USubStr(::db:cQuery, hb_UAt(" ", ::db:cQuery))
            table := firstString(table)
            mode := "incluir"
        otherwise // START, ROOLBACK ou COMMIT
            table := ""
            mode := "executar transação"
    endcase

    if !Empty(table)
        table := Capitalize(table)
    endif

    if ::db:NetErr() .and. !::serverBusy()
        if ("DUPLICATE ENTRY" $ hmg_upper(::db:Error()))
            saveLog({"Erro de duplicidade ao " + mode + " " + table, ansi_to_unicode(::sql)}, "Error")
        elseif ("lost connection" $ hmg_lower(::db:Error()))
            // Esse erro é tratado na linha 37
            saveLog({"Conexão perdida! Erro ao " + mode + iif(Empty(table), " ", " na tabela de " + table), "Erro: " + ::db:Error()}, "Error")
        else
            saveLog({"Erro ao " + mode + iif(Empty(table), " ", " na tabela de " + table), "Erro: " + ::db:Error(), ansi_to_unicode(::db:cQuery)}, "Error")
        endif
        ::db:Destroy()
        msgNotify({'notifyTooltip' => "Erro de conexão Database" + hb_eol() + "Ver Log do sistema"})
    elseif (command $ "SELECT|START|ROOLBACK|COMMIT")
        // Query SELECT Executada com sucesso!
        ::executed := true
        ::db:goTop()
    else
        /* Query INSERT, UPDATE ou DELETE executada com sucesso!
           Verifica se houve algum registro afetado ou não
        */
        if (mysql_affected_rows(::db:nSocket) <= 0)
            saveLog({"Não foi possível " + mode + " na tabela de " + table, "Registros afetados: " +;
                hb_ntos(mysql_affected_rows(::db:nSocket)), mysql_error(::db:nSocket), ansi_to_unicode(::db:cQuery)}, "Warning")
            msgNotify({'notifyTooltip' => "Não foi possível " + mode + " na tabela de " + table + hb_eol() + "Ver Log do sistema"})
            ::db:Destroy()
        else
            ::executed := true
        endif
    endif

return ::executed

method serverBusy() class TQuery
    local ocupado := (::db:NetErr() .and. 'server has gone away' $ ::db:Error())
    if ocupado
        // Força a reconexão caso o servidor tenha "desaparecido" (ocupado)
        saveLog({"Servidor ocupado! Reconectando...", "Erro: " + ::db:Error()}, "Warning")
        appDataSource:disconnect()
        appDataSource:connect()
    endif
return ocupado

method Destroy() class TQuery
    if !(::db == nil)
        ::db:Destroy()
        ::db := nil
    endif
return self

#include "hmg.ch"
#include <hbclass.ch>

class TAppData

    data version readonly
    data utc readonly
    data systemPath readonly
    data dfePath readonly
    data executable readonly
    data executableName readonly
    data winRegistryRoot readonly
    data winRegistryPath readonly
    data displayName readonly
    data supportUrl readonly
    data timer
    data timerStart readonly
    data timerEnd readonly
    data frequency readonly
    data lastMessage
    data cte_sefaz_offline
    data mdfe_sefaz_offline

    method new(version) constructor
    method registerSystem()
    method isRunning()
    method registerDatabase()
    method setUTC(emp_id)
    method setTimer() inline ::timer := Seconds()
    method setDfePath(path)

end class

method new(version) class TAppData
    default version := "4.0.00"

    ::version := version
    ::utc := "-03:00"
    ::systemPath := hb_cwd()
    ::dfePath := "C:\shared\DFe\"   // Default da pasta destino de XMLs e PDFs no servidor do emitente
    ::executable := hb_FNameNameExt(hb_ProgName())
    ::executableName := hb_FNameNameExt(hb_FNameName(hb_ProgName()))
    ::winRegistryRoot := "HKEY_CURRENT_USER\Software\Sistrom\"
    ::winRegistryPath := ::winRegistryRoot + ::executableName + "\"
    ::displayName := "DFeMonitor " + ::version + " (32-bit)"
    ::supportUrl := "https://www.sistrom.com.br"
    ::cte_sefaz_offline := false
    ::mdfe_sefaz_offline := false

return self

method registerSystem() class TAppData

    if !hb_DirExists('tmp')
        hb_DirBuild( 'tmp' ) // Esta função, se precisar, cria pasta e subpastas em um comando só hb_DirBuild('dir1\dir2\dir3')
    endif
    if !hb_DirExists('log')
        hb_DirBuild('log')
    endif
    if !hb_DirExists('certificados')
        hb_DirBuild('certificados')
    endif
    if !hb_DirExists('logotipos')
        hb_DirBuild('logotipos')
    endif
    if (RegistryRead(::winRegistryRoot + "DisplayName") == NIL)
        RegistryWrite(::winRegistryRoot + "DisplayName", "Sistrom Sistemas web")
    endif
    if (RegistryRead(::winRegistryRoot + "SupportUrl") == NIL)
        RegistryWrite(::winRegistryRoot + "SupportUrl", ::supportUrl)
    endif
    if (RegistryRead(::winRegistryPath + "Executable") == NIL)
        RegistryWrite(::winRegistryPath + "Executable", ::executable)
    endif
    if (RegistryRead(::winRegistryPath + "DisplayName") == NIL) .or. !(RegistryRead(::winRegistryPath + "DisplayName") == ::displayName)
        RegistryWrite(::winRegistryPath + "DisplayName", ::displayName)
    endif
    if (RegistryRead(::winRegistryPath + "SysArchitecture") == NIL)
        RegistryWrite(::winRegistryPath + "SysArchitecture", "32bit")
    endif
    if (RegistryRead(::winRegistryPath + "Version") == NIL) .or. !(RegistryRead(::winRegistryPath + "Version") == ::version)
        RegistryWrite(::winRegistryPath + "Version", ::version)
        RegistryWrite(::winRegistryPath + "SysVersion", hb_ULeft(::version, hb_RAt('.', ::version)-1))
    endif
    if (RegistryRead(::winRegistryPath + "SysVersion") == NIL)
        RegistryWrite(::winRegistryPath + "SysVersion", hb_ULeft(::version, hb_RAt('.', ::version)-1))
    endif
    if (RegistryRead(::winRegistryPath + "InstallPath\Path") == NIL)
        RegistryWrite(::winRegistryPath + "InstallPath\Path", hb_cwd())
    endif
    if (RegistryRead(::winRegistryPath + "InstallPath\dfePath") == NIL)
        RegistryWrite(::winRegistryPath + "InstallPath\dfePath", "C:\shared\DFe\")
    else
        ::dfePath := RegistryRead(::winRegistryPath + "InstallPath\dfePath")
    endif
    if !hb_DirExists(::dfePath)
        hb_DirBuild(::dfePath)
    endif
    if (RegistryRead(::winRegistryPath + "Host\db_ServerName") == NIL)
        RegistryWrite(::winRegistryPath + "Host\db_ServerName", "")
    endif
    if (RegistryRead(::winRegistryPath + "Host\db_UserName") == NIL)
        RegistryWrite(::winRegistryPath + "Host\db_UserName", "")
    endif
    if (RegistryRead(::winRegistryPath + "Host\db_Password") == NIL)
        RegistryWrite(::winRegistryPath + "Host\db_Password", "")
    endif
    if (RegistryRead(::winRegistryPath + "Host\db_Port") == NIL)
        RegistryWrite(::winRegistryPath + "Host\db_Port", "")
    endif
    if (RegistryRead(::winRegistryPath + "Host\db_Database") == NIL)
        RegistryWrite(::winRegistryPath + "Host\db_Database", "")
    endif
    if (RegistryRead(::winRegistryPath + "Host\ftp_url") == NIL)
        RegistryWrite(::winRegistryPath + "Host\ftp_url", "")
    endif
    if (RegistryRead(::winRegistryPath + "Host\ftp_server") == NIL)
        RegistryWrite(::winRegistryPath + "Host\ftp_server", "")
    endif
    if (RegistryRead(::winRegistryPath + "Host\ftp_user") == NIL)
        RegistryWrite(::winRegistryPath + "Host\ftp_user", "")
    endif
    if (RegistryRead(::winRegistryPath + "Host\ftp_password") == NIL)
        RegistryWrite(::winRegistryPath + "Host\ftp_password", "")
    endif
    if (RegistryRead(::winRegistryPath + "Monitoring\TimerStart") == NIL)
        RegistryWrite(::winRegistryPath + "Monitoring\TimerStart", "23:00")
    endif
    if (RegistryRead(::winRegistryPath + "Monitoring\TimerEnd") == NIL)
        RegistryWrite(::winRegistryPath + "Monitoring\TimerEnd", "08:00")
    endif
    if (RegistryRead(::winRegistryPath + "Monitoring\frequency") == NIL)
        RegistryWrite(::winRegistryPath + "Monitoring\frequency", 10)
    endif
    if (RegistryRead(::winRegistryPath + "Monitoring\Running") == NIL)
        RegistryWrite(::winRegistryPath + "Monitoring\Running", 0)
    endif
    if (RegistryRead(::winRegistryPath + "Monitoring\DontRun") == NIL)
        RegistryWrite(::winRegistryPath + "Monitoring\DontRun", 0)
    endif
    if (RegistryRead(::winRegistryPath + "Monitoring\Stop_Execution") == NIL)
        RegistryWrite(::winRegistryPath + "Monitoring\Stop_Descricao", "Compatibilidade com o RemoteUpdate")
        RegistryWrite(::winRegistryPath + "Monitoring\Stop_Execution", 0)
    endif
    if (RegistryRead(::winRegistryPath + "nuvemFiscal\token") == NIL)
        RegistryWrite(::winRegistryPath + "nuvemFiscal\token", "")
    endif
    if (RegistryRead(::winRegistryPath + "nuvemFiscal\expires_in") == NIL)
        RegistryWrite(::winRegistryPath + "nuvemFiscal\expires_in", Date()-2)
    endif

    if ::isRunning()
        saveLog('O sistema não foi desligado corretamente da última vez')
    else
        RegistryWrite(::winRegistryPath + "Monitoring\Running", 1)
    endif
    AEval(Directory("log\*.*"), {|aFile| iif(aFile[3] <= (Date()-70), hb_FileDelete("log\"+aFile[1]), NIL)})
    AEval(Directory("tmp\*.*"), {|aFile| iif(aFile[3] <= (Date()-10), hb_FileDelete("tmp\"+aFile[1]), NIL)})
    AEval(Directory("ftp-*.log"), {|aFile| iif(aFile[3] <= (Date()-30), hb_FileDelete(aFile[1]), NIL)})
    saveLog(hb_eol() + hb_eol() + ::displayName + ' - Sistema iniciado (monitorando...)' + hb_eol())

return nil

method isRunning() class TAppData
return isTrue(RegistryRead(::winRegistryPath + "Monitoring\Running"))

method registerDatabase() class TAppData
    local hEnv, mysql, port, db, ftp, respTec

    ::TimerStart := RegistryRead(::winRegistryPath + "Monitoring\TimerStart")
    ::TimerEnd := RegistryRead(::winRegistryPath + "Monitoring\TimerEnd")
    ::frequency := RegistryRead(::winRegistryPath + "Monitoring\frequency")

    /*
        O arquivo ".env.json" existe na primeira instalação do sistema no servidor do cliente e é oculto
        Verifica se o arquivo oculto ".env.json" existe, se existe carrega para o RegEdit a configuração
        inicial com dados sensíveis (key, token, logins de db e ftp), em seguida deleta o aquivo ".env.json"
    */
    if hb_FileExists(".env.json")
        hEnv := hb_jsonDecode(hb_MemoRead(".env.json"))
        if hb_HGetRef(hEnv, "mysql") .and. hb_HGetRef(hEnv, "ftp")
            mysql := hEnv["mysql"]
            ftp := hEnv["ftp"]
            port := hb_HGetDef(mysql, "port", "")
            db := hb_HGetDef(mysql, "database", "")
            RegistryWrite(::winRegistryPath + "Host\db_ServerName", CharXor(mysql["server"], "SysWeb2023"))
            RegistryWrite(::winRegistryPath + "Host\db_UserName", CharXor(mysql["user"], "SysWeb2023"))
            RegistryWrite(::winRegistryPath + "Host\db_Password", CharXor(mysql["password"], "SysWeb2023"))
            RegistryWrite(::winRegistryPath + "Host\db_Port", iif(Empty(port), "", CharXor(port, "SysWeb2023")))
            RegistryWrite(::winRegistryPath + "Host\db_Database", iif(Empty(db), "", CharXor(db, "SysWeb2023")))
            RegistryWrite(::winRegistryPath + "Host\ftp_url", CharXor(ftp["url"], "SysWeb2023"))
            RegistryWrite(::winRegistryPath + "Host\ftp_server", CharXor(ftp["server"], "SysWeb2023"))
            RegistryWrite(::winRegistryPath + "Host\ftp_user", CharXor(ftp["user"], "SysWeb2023"))
            RegistryWrite(::winRegistryPath + "Host\ftp_password", CharXor(ftp["password"], "SysWeb2023"))
        endif
        if hb_HGetRef(hEnv, "respTec")
            respTec := hEnv["respTec"]
            RegistryWrite(::winRegistryPath + "Host\respTec\CNPJ", respTec["CNPJ"])
            RegistryWrite(::winRegistryPath + "Host\respTec\xContato", respTec["xContato"])
            RegistryWrite(::winRegistryPath + "Host\respTec\email", respTec["email"])
            RegistryWrite(::winRegistryPath + "Host\respTec\fone", respTec["fone"])
        endif

        hb_FileDelete(".env.json", "H")
        hb_FileDelete(".env.json")
    endif

    ::timer := seconds()

return nil

method setUTC(emp_id) class TAppData
    ::utc := appEmpresas:getUTC(emp_id)
return nil

method setDfePath(path) class TAppData
    local lSet := false
    if !Empty(path)
        path := AllTrim(path)
        if !(hb_URight(path, 1) == "\")
            path += "\"
        endif
        ::dfePath := path
        lSet := true
    endif
return lSet
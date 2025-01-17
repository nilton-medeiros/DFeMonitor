#include "hmg.ch"
#include <hbclass.ch>

#define MODO_ASSINCRONO .F.

class TAuthNuvemFiscal

    data regPath readonly
    data token
    data expires_in readonly
    data Authorized readonly

    method new() constructor
    method getNewToken()
    method ChecksTokenExpired()

end class

method new() class TAuthNuvemFiscal
    ::regPath := appData:winRegistryPath
    ::token := CharXor(RegistryRead(::regPath + "nuvemFiscal\token"), "SysWeb2023")
    ::expires_in := StoD(RegistryRead(::regPath + "nuvemFiscal\expires_in"))
    ::ChecksTokenExpired()
return Self

method ChecksTokenExpired() class TAuthNuvemFiscal
    if Empty(::expires_in) .or. (::expires_in < Date())
        // Ainda não tem token ou garante o novo token 2 dias antes de expirar
        ::Authorized := ::getNewToken()
    else
        ::Authorized := true
    endif
return ::Authorized

method getNewToken() class TAuthNuvemFiscal
    local lAuth := false, lError := false
    local empresa := appEmpresas:empresas[1]    // as Keys são as mesmas para todas as empresas
    local url := "https://auth.nuvemfiscal.com.br/oauth/token"
    local connection, response
	local content_type := "application/x-www-form-urlencoded"
    local client_id := empresa:nuvemfiscal_client_id
    local client_secret := empresa:nuvemfiscal_client_secret
    local scope := "cte mdfe cnpj empresa cep conta"
    local hResp, objError, msgError, body, log := {=>}

    begin sequence
        connection := win_oleCreateObject("MSXML2.ServerXMLHTTP.6.0")   // usa msxml6.dll (esta funciona em Win10/11)
        // connection := win_oleCreateObject("Microsoft.XMLHTTP")       // Usa msxml3.dll (não funciona Win7/10/11)
        if Empty(connection)
            log["type"] := "Error"
            log["description"] := "Erro na criação do serviço: MSXML2: win_oleCreateObject('MSXML2.ServerXMLHTTP.6.0') retornou type: " + ValType(connection)
            apiLog(log)
            lError := true
            Break
        endif
    end sequence

    if lError
        return false
    endif

    begin sequence

        connection:Open("POST", url, MODO_ASSINCRONO)
        connection:SetRequestHeader("Content-Type", content_type)

        /*  Os parâmetros são separados pelo & (ê comercial),
            mas o Harbour interpreta como macro substituição!
            Neste caso, é preciso usar o chr(38) para impor o &
            a cada parâmentro na string body
         */
        body := "grant_type=client_credentials"
        body += chr(38) + "client_id=" + client_id
        body += chr(38) + "client_secret=" + client_secret
        body += chr(38) + "scope=" + scope

        connection:Send(body)
        connection:WaitForResponse(5000)

    recover using objError
        msgError := MsgDebug(connection)
        log["type"] := "Error"
        if (objError:genCode == 0)
            log["description"] := "Erro de conexão com o site"
        else
            log["description"] := objError:description + " - Erro de conexão com o site"
        endif
        log["msgDebug"] := msgError
        apiLog(log)
        lError := true
        Break
    end sequence

    if lError
        return false
    endif

    response := connection:ResponseBody
    hResp := hb_jsonDecode(response)

    // Coleta de informações para o Log da API
    log["method"] := "POST"
    log["url"] := url
    log["content_type"] := content_type

    if hb_HGetRef(hResp, "access_token")
        ::token := hResp["access_token"]
        // Converte os segundos em dia (até segunda ordem da nuvem fiscal, é sempre 2592000's, que dá 30 dias)
        ::expires_in := Date() + hResp["expires_in"]/60/60/24
        ::expires_in := ::expires_in -2 // Menos 2 dias para garantir a renovação antes de expirar efetivamente
        RegistryWrite(::regPath + "nuvemFiscal\token", CharXor(::token, "SysWeb2023"))
        RegistryWrite(::regPath + "nuvemFiscal\expires_in", DtoS(::expires_in))
        lAuth := true
        log["type"] := "Debug"
        log["description"] := "HTTP Status: " + hb_ntos(connection:Status) + " | Novo token obtido com sucesso!"
    else
        msgError := MsgDebug(response, hResp)
        log["type"] := "Warning"
        log["description"] := "HTTP Status: " + hb_ntos(connection:Status) + " | Falha na autenticação com a API da NuvemFiscal, o responseBody (hResp) retornou vazio"
        log["MsgDebug"] := msgError
    endif

    apiLog(log)
    log := Nil

return lAuth
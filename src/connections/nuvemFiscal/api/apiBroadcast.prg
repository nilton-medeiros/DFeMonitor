#include "hmg.ch"

/*
    Broadcast: Transmitir
    Transmite à API da Nuvem Fiscal a solicitação (endpoint) e json
    (body) de acordo com o método http solicitado.
*/
function Broadcast(connection, httpMethod, apiUrl, token, operation, body, content_type, accept)
    local oError, log := {=>}
    local response := {"error" => false, "http_status" => 0, "ContentType" => "", "response" => "", "sefazOff" => {=>}, "error_code" => 0}
    local sefazOFF

    try

        connection:Open(httpMethod, apiUrl, false)
        connection:SetRequestHeader("Authorization", "Bearer " + token)

        if Empty(content_type)
            content_type := ""
        else
            connection:SetRequestHeader("Content-Type", content_type)   // Request Body Schema
        endif
        if !Empty(accept)
            connection:SetRequestHeader("Accept", accept)
        endif
        // if (operation == "Baixar XML do CTe")
            // Seta o Request Follow redirects = True (redirecionamento de url automático)
            // connection:Option(WHR_EnableRedirects) := true
        // endif

        if Empty(body)

            try
                connection:Send()
            catch oError
                if (oError:genCode == 0)
                    apiLog({"type" => "Error", "description" => "Erro em WinOle MSXML6.DLL"})
                    Break
                else
                    response["error_code"] := oError:genCode
                    if ("O tempo limite da opera" $ oError:description)
                        apiLog({"type" => "Error", "description" => "Error " + hb_ntos(oError:genCode) + ": " + oError:description + " ... Tentando mais uma vez..."})
                        SysWait(10)  // Aguarda 10 segundos e tenta novamente
                        connection:Send()
                    else
                        apiLog({"type" => "Error", "description" => "Erro em Send() para API Nuvem Fiscal: " + oError:description})
                        Break
                    endif
                endif
            end

        else
            // Request Body
            try
                connection:Send(body)
            catch oError
                if (oError:genCode == 0)
                    apiLog({"type" => "Error", "description" => "Erro em WinOle MSXML6.DLL"})
                    Break
                else
                    response["error_code"] := oError:genCode
                    if ("o tempo limite da opera" $ Lower(oError:description))
                        apiLog({"type" => "Error", "description" => "Error " + hb_ntos(oError:genCode) + ": " + oError:description + " ... Tentando mais uma vez..."})
                        SysWait(10)  // Aguarda 10 segundos e tenta novamente
                        connection:Send(body)
                    else
                        apiLog({"type" => "Error", "description" => "Erro em Send() para API Nuvem Fiscal: " + oError:description})
                        Break
                    endif
                endif
            end

        endif

        if ("image" $ content_type)
            connection:WaitForResponse(70000)
        else
            connection:WaitForResponse(5000)
        endif

    catch oError

        log["type"] := "Error"
        log["method"] := httpMethod
        log["url"] := apiUrl
        log["content_type"] := iif(content_type == nil, "$$null$$", content_type)
        log["accept"] := iif(accept == nil, "$$null$$", accept)
        log["body"] := iif(body == nil, "$$null$$", iif("image" $ content_type, "[ ARQUIVO BINARIO DA IMAGEM ]", body))

        if (oError:genCode == 0)
            log["description"] := "Erro desconhecido de conexão com o site"
            log["response"] := "Erro desconhecido de conexão com o site " + operation
            response["response"] := "Erro de conexão com a API Nuvem Fiscal em " + operation
        else
            response["error_code"] := oError:genCode
            log["description"] := "Error " + hb_ntos(oError:genCode) + ": " + oError:description
            log["response"] := "Erro de conexão com API Nuvem Fiscal em " + operation
            response["response"] := "Erro de conexão com a API Nuvem Fiscal em " + operation + " | " + oError:description
        endif
        apiLog(log)
        log := nil
        response["error"] := true
        response["ContentType"] := "text"
        // Break
    end

    if !response["error"]

        response["http_status"] := connection:Status

        if (response["http_status"] > 199) .and. (response["http_status"] < 300)

            // Entre 200 e 299
            if !Empty(connection:ResponseBody)
                response["response"] := connection:ResponseBody
                response["ContentType"] := "json"
            endif

        else    // elseif (response["http_status"] > 399) .and. (response["http_status"] < 600)

            if ("json" $ connection:getResponseHeader("Content-Type"))

                // "application/json"
                response["ContentType"] := "json"
                response["response"] := connection:ResponseBody

                sefazOFF := hb_jsonDecode(response["response"])

                if hb_HGetRef(sefazOFF, "status") .and. hb_HGetRef(sefazOFF, "autorizacao")

                    sefazOFF := sefazOFF["autorizacao"]

                    if hb_HGetRef(sefazOFF, "motivo_status")
                        if "the server name cannot be resolved" $ Lower(sefazOFF["motivo_status"])
                            response["sefazOff"]["id"] := sefazOFF["id"]
                            response["sefazOff"]["codigo_status"] := sefazOFF["codigo_status"]
                            response["sefazOff"]["motivo_status"] := sefazOFF["motivo_status"]
                        elseif response["http_status"] == 500 .and. ("internal server error" $ Lower(sefazOFF["motivo_status"]))
                            log["type"] := "Error"
                            log["method"] := httpMethod
                            log["url"] := apiUrl
                            log["content_type"] := iif(content_type == nil, "$$null$$", content_type)
                            log["accept"] := iif(accept == nil, "$$null$$", accept)
                            log["body"] := iif(body == nil, "$$null$$", iif("image" $ content_type, "[ ARQUIVO BINARIO DA IMAGEM ]", body))
                            log["description"] := "HTTP Status: 500 - Internal Server Error, " + sefazOFF["motivo_status"]
                            log["response"] := iif(response["response"] == nil .or. Empty(response["response"]), "$$null$$", ;
                                iif((Lower(Left(operation, 6)) == "baixar"), "Response é um ARQUIVO BINÁRIO", response["response"]))
                            apiLog(log)
                            MsgStop({"Erro no servidor da api de DFe", hb_eol(), "Erro: ", sefazOFF["motivo_status"]}, "DFeMonitor " + appData:version + ": Erro HTTP:500")
                            turnOFF()
                        endif
                    endif

                endif

            else
                // "application/text"
                response["ContentType"] := "text"
                if !Empty(connection:ResponseText)
                    response["response"] := connection:ResponseText
                elseif !Empty(connection:ResponseBody)
                    response["response"] := connection:ResponseBody
                else
                    response["response"] := "ResponseText e ResponseBody retornaram vazio, sem mensagem"
                endif
            endif

            response["error"] := true

        endif

        log["type"] := "Information"
        log["method"] := httpMethod
        log["url"] := apiUrl
        log["content_type"] := iif(content_type == nil, "$$null$$", content_type)
        log["accept"] := iif(accept == nil, "$$null$$", accept)
        log["body"] := iif(body == nil, "$$null$$", iif("image" $ content_type, "[ ARQUIVO BINARIO DA IMAGEM ]", body))
        log["description"] := "HTTP Status: " + hb_ntos(response["http_status"]) + " - " + operation
        log["response"] := iif(response["response"] == nil .or. Empty(response["response"]), "$$null$$", ;
            iif((Lower(Left(operation, 6)) == "baixar"), "Response é um ARQUIVO BINÁRIO", response["response"]))

        apiLog(log)

    endif

return response

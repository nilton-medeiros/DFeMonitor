#include "hmg.ch"

/*
    Broadcast: Transmitir
    Transmite à API da Nuvem Fiscal a solicitação (endpoint) e json
    (body) de acordo com o método http solicitado.
*/
function Broadcast(connection, httpMethod, apiUrl, token, operation, body, content_type, accept)
    local oError
    local response := {"error" => false, "http_status" => 0, "ContentType" => "", "response" => "", "sefazOff" => {=>}}
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

        if Empty(body)

            try
                connection:Send()
            catch oError
                if (oError:genCode == 0)
                    saveLog("Erro em WinOle MSXML6.DLL")
                    Break
                else
                    if ("O tempo limite da opera" $ oError:description)
                        saveLog("Erro: " + oError:description + " ... Tentando mais uma vez...")
                        SysWait(10)  // Aguarda 10 segundos e tenta novamente
                        connection:Send()
                    else
                        saveLog("Erro em Send() para API Nuvem Fiscal: " + oError:description)
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
                    saveLog("Erro em WinOle MSXML6.DLL")
                    Break
                else
                    if ("o tempo limite da opera" $ Lower(oError:description))
                        saveLog("Erro: " + oError:description + " ... Tentando mais uma vez...")
                        SysWait(10)  // Aguarda 10 segundos e tenta novamente
                        connection:Send(body)
                    else
                        saveLog("Erro em Send() para API Nuvem Fiscal: " + oError:description)
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
        if (oError:genCode == 0)
            consoleLog({"Debug: " + operation + " | URL API (", httpMethod + "): ", apiUrl, hb_eol(), ;
                "content_type: ", iif(content_type == nil, "NULL", content_type), hb_eol(), ;
                "accept: ", iif(accept == nil, "NULL", accept), hb_eol(), ;
                "Body: ", iif(body == nil, "NULL", iif("image" $ content_type, "[ ARQUIVO BINARIO DA IMAGEM ]", body)), hb_eol(), ;
                "Erro desconhecido de conexão com o site", hb_eol(), hb_eol()})
            saveLog({"Erro de conexão com API Nuvem Fiscal em " + operation, hb_eol(), hb_eol(), hb_eol()})
            response["response"] := "Erro de conesão com a API Nuvem Fiscal em " + operation
        else
            consoleLog({"Debug: " + operation + " | URL API (", httpMethod + "): ", apiUrl, hb_eol(), ;
                "content_type: ", iif(content_type == nil, "NULL", content_type), hb_eol(), ;
                "accept: ", iif(accept == nil, "NULL", accept), hb_eol(), ;
                "Body: ", iif(body == nil, "NULL", iif("image" $ content_type, "[ ARQUIVO BINARIO DA IMAGEM ]", body)), hb_eol(), ;
                "Erro de conexão com API Nuvem Fiscal", hb_eol(), "Error: ", oError:description, hb_eol(), hb_eol()})
            saveLog({"Erro de conexão com API Nuvem Fiscal em " + operation, hb_eol(), "Error: ", oError:description, hb_eol()})
            response["response"] := "Erro de conesão com a API Nuvem Fiscal em " + operation + " | " + oError:description
        endif
        response["error"] := true
        response["ContentType"] := "text"
        Break
    end

    if response["error"]
        // Debug: Remover esta linha e a debaixo após testes
        if (Lower(Left(operation, 6)) == "baixar")
            consoleLog({"Debug: " + operation + " |ContentType: " + response["ContentType"]})
        else
            consoleLog({"Debug: " + operation + " |ContentType: " + response["ContentType"] + " |Response: ", hb_eol(), response["response"]})
        endif
    else

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
                            consoleLog({"Debug: " + operation + ;
                                " | HTTP Status: ", response["http_status"], hb_eol(), ;
                                "URL API (", httpMethod + "): ", apiUrl, hb_eol(), ;
                                "content_type: ", iif(content_type == nil, "NULL", content_type), hb_eol(), ;
                                "accept: ", iif(accept == nil, "NULL", accept), hb_eol(), ;
                                "Body: ", iif(body == nil, "NULL", iif("image" $ content_type, "[ ARQUIVO BINARIO DA IMAGEM ]", body)), hb_eol(), ;
                                "Response: ", iif(response["response"] == nil .or. Empty(response["response"]), "NULL", ;
                                            iif((Lower(Left(operation, 6)) == "baixar"), "Response é um ARQUIVO BINÁRIO", response["response"])) ;
                            })
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

        // Debug: Remover esta linha e a debaixo após testes
        consoleLog({"Debug: " + operation + ;
            " | HTTP Status: ", response["http_status"], hb_eol(), ;
            "URL API (", httpMethod + "): ", apiUrl, hb_eol(), ;
            "content_type: ", iif(content_type == nil, "NULL", content_type), hb_eol(), ;
            "accept: ", iif(accept == nil, "NULL", accept), hb_eol(), ;
            "Body: ", iif(body == nil, "NULL", iif("image" $ content_type, "[ ARQUIVO BINARIO DA IMAGEM ]", body)), hb_eol(), ;
            "Response: ", iif(response["response"] == nil .or. Empty(response["response"]), "NULL", ;
                          iif((Lower(Left(operation, 6)) == "baixar"), "Response é um ARQUIVO BINÁRIO", response["response"])) ;
        })

    endif

return response

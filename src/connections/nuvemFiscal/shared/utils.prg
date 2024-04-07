// Função compartilhada entre as classes API Nuvem Fiscal para obter uma conexão MSXML2 objeto OLE

#include "hmg.ch"

function GetMSXMLConnection()
	local connection, descr := {}

    begin sequence
        connection := win_oleCreateObject("MSXML2.ServerXMLHTTP.6.0")
        if Empty(connection)
			AAdd(descr, win_oleErrorText())
			AAdd(descr, "Erro na criação do serviço: MSXML2, win_oleCreateObject('MSXML2.ServerXMLHTTP.6.0') retornou type: " + ValType(connection))
			apiLog({"type" => "Error", "description" => descr})
            Break
        endif
    end sequence

return connection

/*
function GetWinHttpConnection()
	local connection, descr := {}

	begin sequence
		connection := win_oleCreateObject("WinHttp.WinHttpRequest.5.1")
        if Empty(connection)
			AAdd(descr, win_oleErrorText())
			AAdd(descr, "Erro na criação do serviço: WinHTTP, win_oleCreateObject('WinHttp.WinHttpRequest.5.1') retornou type: " + ValType(connection))
			apiLog({"type" => "Error", "description" => descr})
            Break
        endif
    end sequence

return connection
*/

// Função utilizada para obter resposta de erros retornados, deve ser refatorada para ler o array de errors
function getMessageApiError(api, lAsText)
	local response, textError := "", aError := {}, error, n := 0

	default lAsText := true

	if (api:ContentType == "json")
		response := hb_jsonDecode(api:response)
		if hb_HGetRef(response, "error")
			response := response["error"]
			AAdd(aError, {"code" => response["code"], "message" => response["message"]})
			if hb_HGetRef(response, "errors")
				response := response["errors"]
				for each error in response
					AAdd(aError, error)
				next
			endif
		elseif hb_HGetRef(response, "status")
			AAdd(aError, {"code" => response["codigo_status"], "message" => response["motivo_status"]})
		else
			apiLog({"type" => "Error", "description" => "Nao encontrado a chave 'error' no objeto response, json desconhecido!", "response" => response})
			AAdd(aError, {"code" => "sem código", "message" => "Chaves do json desconhecidas, avisar suporte (ver log do sitema)"})
		endif
		if lAsText
			for each error in aError
				if (++n > 1)
					textError += hb_eol()
				endif
				textError += "Código: " + error["code"] + hb_eol()
				textError += "Mensagem: " + error["message"]
			next
		endif
	else
		if lAsText
			textError := api:response
		else
			AAdd(aError, {"code" => "sem código", "message" => api:response})
		endif
	endif

return iif(lAsText, textError, aError)

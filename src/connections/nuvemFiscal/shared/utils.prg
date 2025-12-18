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
/*
	Tipos de erros em json retornados
	Um erro:
		"response": {
			"error": {
				"code": "ValidationFailed",
				"message": "Operação não permitida para a situação atual do documento."
			}
		},

	Array de erros:
		"response": {
			"error": {
				"code": "ValidationFailed",
				"message": "Validation failed: O campo 'infCte.infCTeNorm.infDoc.infNFe[0].chave' não corresponde ao formato esperado ^([0-9]{6}[A-Z0-9]{12}[0-9]{26})$",
				"errors": [
					{
						"code": "InvalidFormat",
						"message": "O campo 'infCte.infCTeNorm.infDoc.infNFe[0].chave' não corresponde ao formato esperado ^([0-9]{6}[A-Z0-9]{12}[0-9]{26})$"
					}
				]
			}
		},
*/
function getMessageApiError(api, lAsText)
	local response, textError := "", autorizacao, aData, aError := {}, error, n := 0

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
			if Lower(api:status) == "erro"
				AAdd(aError, {"code" => api:codigo_status, "message" => api:motivo_status})
			else
				AAdd(aError, {"code" => response["codigo_status"], "message" => response["motivo_status"]})
			endif
		elseif hb_HGetRef(response, "data")
			aData := response["data"]
			if Empty(aData) .or. !hb_HGetRef(aData[1], "autorizacao")
				apiLog({"type" => "Error", "description" => "A chave 'data' do json retornou vazia!", "response" => response})
				AAdd(aError, {"code" => "sem código", "message" => "A chave do json 'data' retornou vazia, avisar suporte (ver log do sitema)"})
			else
				response := aData[1]
				autorizacao = response["autorizacao"]
				AAdd(aError, {"code" => autorizacao["codigo_status"], "message" => autorizacao["motivo_status"]})
			endif
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

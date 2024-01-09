/*
    Rotina de teste: getNumber(dfe)
    Obtem o próximo número do DFe em homologação
    para testes de emissão na nuvem fiscal
*/

function dfeGetNumber(dfeKey)
    local nextNumbers, numeroDFe, jsonFile := appData:systemPath + 'tests\db\' + "dfeNumbers.json"

    if hb_FileExists(jsonFile)
        nextNumbers := hb_jsonDecode(hb_MemoRead(jsonFile))
    else
        nextNumbers := {"cte" => 1, "dbCTe" => 44502, "mdfe" => 1}
    endif

    numeroDFe := hb_HGetDef(nextNumbers, dfeKey, 1)
    nextNumbers[dfeKey] := numeroDFe + 1

    hb_MemoWrit(jsonFile, hb_jsonEncode(nextNumbers, 4))

return numeroDFe

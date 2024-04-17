#include "hmg.ch"
#include "hbclass.ch"

class TEmpresa

    data id readonly
    data cia readonly
    data xNome readonly
    data xFant readonly
    data CNPJ
    data cnpj_contabil readonly
    data IE readonly
    data IM readonly
    data xLgr readonly
    data nro readonly
    data xCpl readonly
    data xBairro readonly
    data cUF readonly
    data xMunEnv readonly
    data cMunEnv readonly
    data UF readonly
    data CEP readonly
    data fone readonly
    data cte_versao_xml readonly
    data mdfe_versao_xml readonly
    data tpAmb readonly
    data modal readonly
    data RNTRC readonly
    data utc readonly
    data remote_file_path readonly
    data email readonly
    data seguradora readonly
    data apolice readonly
    data CRT readonly
    data tpImp readonly
    data nuvemfiscal_client_id readonly
    data nuvemfiscal_client_secret readonly
    data nuvemfiscal_cadastrar readonly
    data nuvemfiscal_alterar readonly
    data tpEmit readonly

    method new(empresa) constructor
    method update()

end class

method new(empresa) class TEmpresa
    local versao := hb_ntos(empresa['cte_versao_xml'])
    // Converte numérico para string

    if (Len(Token(versao, ".")) == 1)
        versao += "0"
    endif

    ::id := empresa['id']
    ::cia := AllTrim(empresa['cia'])
    ::xNome := empresa['xNome']
    ::xFant := empresa['xFant']
    ::CNPJ := getNumbers(empresa['CNPJ'])
    ::cnpj_contabil := getNumbers(empresa['cnpj_contabil'])
    ::IE := empresa['IE']
    ::IM := empresa['IM']
    ::xLgr := empresa['xLgr']
    ::nro := empresa['nro']
    ::xCpl := empresa['xCpl']
    ::xBairro := empresa['xBairro']
    ::cUF := number_format(empresa['cUF'])
    ::xMunEnv := empresa['xMunEnv']
    ::cMunEnv := hb_ntos(empresa['cMunEnv'])
    ::UF := empresa['UF']
    ::CEP := getNumbers(empresa['CEP'])
    ::fone := getNumbers(empresa['fone'])
    ::cte_versao_xml := versao
    ::mdfe_versao_xml := empresa['mdfe_versao_xml']
    ::tpAmb := empresa['tpAmb']
    ::modal := empresa['modal']
    ::RNTRC := empresa['RNTRC']
    ::utc := empresa['utc']
    ::remote_file_path := empresa['remote_file_path']
    ::email := empresa['email']
    ::seguradora := empresa['seguradora']
    ::apolice := empresa['apolice']
    ::CRT := empresa['CRT']
    ::tpImp := empresa['tpImp']
    ::nuvemfiscal_client_id := empresa['nuvemfiscal_client_id']
    ::nuvemfiscal_client_secret := empresa['nuvemfiscal_client_secret']
    ::nuvemfiscal_cadastrar := iif(empresa['nuvemfiscal_cadastrar'] == 1, true, false)
    ::nuvemfiscal_alterar := iif(empresa['nuvemfiscal_alterar'] == 1, true, false)
    ::tpEmit := empresa['tpEmit']

return self

method update() class TEmpresa
    local changed := appEmpresas:update(::id)
    if changed
        ::nuvemfiscal_alterar := false
        ::nuvemfiscal_alterar := false
    else
        saveLog("Erro ao atualizar banco de dados tabela empresa! Sistema abortado", "Critical")
        MsgExclamation("Erro ao atualizar empresa, avise ao suporte!", "DFeMonitor " + appData:version + ": Erro! Sistema será parado")
        turnOFF()
    endif
return changed

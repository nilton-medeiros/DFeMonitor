procedure testBaixarArquivos()
    local cte, ctes := TDbCTes():new()
    local baixar, targetFile, empresa, anoMes, directory

    ctes:getListCTes()
    cte := ctes:ctes[1]
    cte:chCTe := "35231057296543000115570010000000071000619173"
    baixar := TApiCTe():new(cte)
    baixar:nuvemfiscal_uuid := "cte_3a0e2918fd064e3c85f7b0208df9779b"
    baixar:chave := "35231057296543000115570010000000021660513554"

    empresa := appEmpresas:getEmpresa(cte:emp_id)

    // "2019-08-24T14:15:22Z"
    anoMes := hb_ULeft(getNumbers(baixar:data_emissao), 6)
    directory := appData:dfePath + empresa:CNPJ + '\CTe\' + anoMes + '\'

    if !hb_DirExists(directory)
        hb_DirBuild(directory)
    endif

    if baixar:BaixarPDFdoDACTE()
        targetFile := baixar:chave + '-cte.pdf'
        if hb_MemoWrit(directory + targetFile, baixar:pdf_dacte)
            saveLog("Arquivo PDF do DACTE salvo com sucesso: " + directory + targetFile)
            // Aqui: Subir o arquivo para o servidor remoto
            // uploadPDFdoDACTE(directory + targetFile)
        else
            saveLog("Erro ao escrever pdf binary em arquivo " + targetFile + " na pasta " + directory)
        endif
    else
        saveLog("Arquivo PDF do DACTE não retornado; CTe Chave: " + baixar:chave)
    endif

    if baixar:BaixarXMLdoCTe()
        targetFile := baixar:chave + '-cte.xml'
        if hb_MemoWrit(directory + targetFile, baixar:xml_cte)
            saveLog("Arquivo XML do CTe salvo com sucesso: " + directory + targetFile)
            // Aqui: Subir o arquivo para o servidor web
            // uploadXMLdoCTe(directory + targetFile)
        else
            saveLog("Erro ao escrever xml binary em arquivo " + targetFile + " na pasta " + directory)
        endif
    else
        saveLog("Arquivo XML do CTe não retornado; CTe Chave: " + baixar:chave)
    endif

    MsgStop("Fim do teste" + hb_eol() + "Verificar pasta C:\shared\DFe", "Baixar Arquivos")
    turnOFF()

return
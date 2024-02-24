#include "hmg.ch"

function cteGetFiles(apiCTe)
    local lExisteAutorizado := lExisteCancelado := false
    local upload := {=>}
    local directory, filePDF, fileXML, cancelPDF, cancelXML
    local empresa, anoMes, printPDF, printPath
    local cte := apiCTe:cte, chave

    // As vars que começam com "app" são de nível global (Public) definidas no main.prg
    empresa := appEmpresas:getEmpresa(cte:emp_id)

    // "2019-08-24T14:15:22Z"
    anoMes := Left(getNumbers(cte:dhEmi), 6)
    directory := appData:dfePath + empresa:CNPJ + '\CTe\' + anoMes + '\'

    if Empty(apiCTe:chave)
        if Empty(cte:chCTe)
            saveLog("Chave do CTe não defindo para gerar arquivo, ver Log da API", "Warning")
            return
        else
            apiCTe:chave := cte:chCTe
            chave := cte:chCTe
        endif
    else
        chave := apiCTe:chave
    endif

    filePDF := chave + '-cte.pdf'
    fileXML := chave + '-cte.xml'
    cancelPDF := chave + '-cteCancelado.pdf'
    cancelXML := chave + '-cteCancelado.xml'

    if hb_DirExists(directory)
        if (Upper(apiCTe:status) == "CANCELADO")
            lExisteAutorizado := true
            lExisteCancelado := hb_FileExists(directory + cancelPDF) .and. hb_FileExists(directory + cancelXML)
            if lExisteCancelado
                upload["pdfCancel"] := directory + cancelPDF
                upload["xmlCancel"] := directory + cancelXML
            endif
        else
            lExisteAutorizado := hb_FileExists(directory + filePDF) .and. hb_FileExists(directory + fileXML)
            if lExisteAutorizado
                upload["pdf"] := directory + filePDF
                upload["xml"] := directory + fileXML
            endif
        endif
    else
        hb_DirBuild(directory)
    endif

    if !lExisteAutorizado

        if apiCTe:BaixarPDFdoDACTE()
            if hb_MemoWrit(directory + filePDF, apiCTe:pdf_dacte)
                upload["pdf"] := directory + filePDF
                saveLog({"Arquivo PDF do DACTE salvo com sucesso", directory + filePDF})
            else
                cte:setUpdateEventos("OBTER PDF", date_as_DateTime(date(), false, false), "BINARY PDF", "Erro ao escrever PDF em arquivo. Ver log servidor local")
                saveLog("Erro ao escrever pdf binary em arquivo " + filePDF + " na pasta " + directory, "Warning")
            endif
        else
            cte:setUpdateEventos("OBTER PDF", date_as_DateTime(date(), false, false), "BINARY PDF", "Arquivo PDF do DACTE não retornado. Ver log servidor local")
            saveLog({"Arquivo PDF do DACTE não retornado", "Chave CTe: " + apiCTe:chave}, "Warning")
        endif

        if apiCTe:BaixarXMLdoCTe()
            if hb_MemoWrit(directory + fileXML, apiCTe:xml_cte)
                upload["xml"] := directory + fileXML
                saveLog({"Arquivo XML do CTe salvo com sucesso", directory + fileXML})
            else
                cte:setUpdateEventos("OBTER XML", date_as_DateTime(date(), false, false), "BINARY XML", "Erro ao escrever XML em arquivo. Ver log servidor local")
                saveLog("Erro ao escrever xml binary em arquivo " + fileXML + " na pasta " + directory, "Warning")
            endif
        else
            cte:setUpdateEventos("OBTER XML", date_as_DateTime(date(), false, false), "BINARY XML", "Arquivo XML do CTe não retornado. Ver log servidor local")
            saveLog({"Arquivo XML do CTe não retornado", "Chave CTe: " + apiCTe:chave}, "Warning")
        endif

    endif

    if (Upper(apiCTe:status) == "CANCELADO") .and. !lExisteCancelado

        if apiCTe:BaixarPDFdoCancelamento()
            if hb_MemoWrit(directory + cancelPDF, apiCTe:pdf_cancel)
                upload["pdfCancel"] := directory + cancelPDF
                saveLog({"Arquivo PDF do CTE CANCELADO salvo com sucesso", directory + cancelPDF})
            else
                cte:setUpdateEventos("OBTER PDF", date_as_DateTime(date(), false, false), "BINARY PDF", "Erro ao escrever PDF do CTe CANCELADO em arquivo. Ver log servidor local")
                saveLog("Erro ao escrever pdf binary em arquivo " + cancelPDF + " na pasta " + directory, "Warning")
            endif
        else
            cte:setUpdateEventos("OBTER PDF", date_as_DateTime(date(), false, false), "BINARY PDF", "Arquivo PDF do CTE CANCELADO não retornado. Ver log servidor local")
            saveLog({"Arquivo PDF do CTE CANCELADO não retornado", "Chave CTe: " + apiCTe:chave}, "Warning")
        endif

        if apiCTe:BaixarXMLdoCancelamento()
            if hb_MemoWrit(directory + cancelXML, apiCTe:xml_cancel)
                upload["xmlCancel"] := directory + cancelXML
                saveLog({"Arquivo XML do CTE CANCELADO salvo com sucesso", directory + cancelXML})
            else
                cte:setUpdateEventos("OBTER XML", date_as_DateTime(date(), false, false), "BINARY XML", "Erro ao escrever XML do CTE CANCELADO em arquivo. Ver log servidor local")
                saveLog("Erro ao escrever xml binary em arquivo " + cancelXML + " na pasta " + directory, "Warning")
            endif
        else
            cte:setUpdateEventos("OBTER XML", date_as_DateTime(date(), false, false), "BINARY XML", "Arquivo XML do CTE CANCELADO não retornado. Ver log servidor local")
            saveLog({"Arquivo XML do CTE CANCELADO não retornado", "Chave CTe: " + apiCTe:chave}, "Warning")
        endif

    endif

    if !Empty(upload)
        printPath := RegistryRead("HKEY_CURRENT_USER\Software\Sistrom\SendToPrinter\InstallPath\Path")
        if !Empty(printPath)
            printPath += "printNow\"
            if hb_HGetRef(upload, "pdf")
                printPDF := printPath + Token(upload["pdf"], "\")
                hb_FCopy(upload["pdf"], printPDF)
            endif
            if hb_HGetRef(upload, "pdfCancel")
                printPDF := printPath + Token(upload["pdfCancel"], "\")
                hb_FCopy(upload["pdfCancel"], printPDF)
            endif
        endif
        upload["cte"] := cte
        upload["empresa"] := empresa
        cteUploadFiles(upload)
    endif

return
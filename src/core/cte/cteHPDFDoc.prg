#include "hmg.ch"
#include "hbclass.ch"

/* ------- hbPDF (HPDFDOC) : Classe para gerenciar HMG HPDF ------- */

class TCTeHPDFDoc
   data filePDF protected
   data logotipo protected
   data paper
   data font
   data success protected
   data title protected
   data subject protected
   data keyWords protected
   data line protected
   data column protected
   data pagina readonly
   data totPag
   data emi
   data rem
   data des
   data exp
   data rec
   data tom
   data modal
   data mod
   data serie
   data nCT
   data tpAmb
   data dhEmi
   data chCTe
   data ISUF
   data nProt
   data tpCTe
   data tpServ
   data indGlobalizado
   data xObs_infGlobalizado
   data cfop
   data iniPrest
   data fimPrest
   data dhCreated protected
   data qtdeDoc protected

   method new(out_path, logo, ch_cte, tpAmb, ind_globalizado) constructor
   method startPDF() setget
   method encoding() setget
   method pageHeader()
   method pageBody()
   method pageFooter() setget
   method setLine(line) setget
   method getLine() inline ::line
   method setColumn() setget
   method setFont()
   method printText()
   method printLine()
   method printLineVertical()
   method printBlockText()
   method printDocsOriginarios()
   method drawBox()
   method getPag()
   method getNamePDF() inline ::filePDF
   method center(iniCol, fimCol)
   method barCodes(key)
   method getDateCreated() inline ::dhCreated
   method setdhCreated()
end class

method new(out_path, logo, ch_cte, tpAmb, ind_globalizado) CLASS TCTeHPDFDoc
   ::filePDF := out_path + ch_cte + '-cte.pdf'
   ::logotipo := logo
   ::chCTe := ch_cte
   ::success := false
   ::title := 'DACTE'
   ::subject := 'Documento Auxiliar do Conhecimento de Transporte Eletrônico'
   ::keyWords := 'CTE, DACTE, Conhecimento, Sistrom'
   ::line := 0
   ::column := 5
   ::pagina := 1
   ::totPag := 1
   ::paper := pdf_paper():new()
   ::font := pdf_Font():new()
   ::emi := TCliente():new()
   ::rem := TCliente():new()
   ::des := TCliente():new()
   ::exp := TCliente():new()
   ::rec := TCliente():new()
   ::tom := TCliente():new()
   ::modal := 'RODOVIÁRIO'
   ::mod := '57'
   ::serie := '999'
   ::nCT := '999999999'
   ::tpAmb := tpAmb
   ::dhEmi := DToC(Date()) + ' ' + Time()
   ::ISUF := ''
   ::nProt := '999999999999999 - 99/99/9999 99:99:99'
   ::tpCTe := 'Normal'
   ::tpServ := 'Normal'
   ::indGlobalizado := ind_globalizado
   if (::indGlobalizado)
      ::xObs_infGlobalizado := 'Resolução/SEFAZ n. 2.833/2017'
   else
      ::xObs_infGlobalizado := ''
   endif
   ::cfop := ''
   ::iniPrest := ''
   ::fimPrest := ''
   ::dhCreated := ''
   ::qtdeDoc := 0
return self

method startPDF() CLASS TCTeHPDFDoc
   if Empty(::filePDF)
      ::success := false
      return ::success
   endif
   hb_FileDelete(::filePDF)
   SELECT HPDFDOC ::filePDF TO ::success ORIENTATION ::paper:orientation PAPERSIZE HPDF_PAPER_A4
   if (::paper:orientation == 1)
      ::paper:width := 210
      ::paper:lenth := 297
   else
      ::paper:width := 297
      ::paper:lenth := 210
   endif
   if ::success
      ::paper:center := Int(::paper:width/2)
      ::paper:right := ::paper:width - ::column
      if Empty(::keyWords)
         ::keyWords := 'Relatório, Sistrom, PDF, CTe'
      endif
      SET HPDFDOC COMPRESS ALL
//      SET HPDFDOC PERMISSION TO COPY  *** Isso não funciona, bloqueia a criação de novas paginas ***
//      SET HPDFDOC PERMISSION TO PRINT  *** Isso não funciona, bloqueia a criação de novas paginas ***
      SET HPDFDOC PAGEMODE TO OUTLINE
      SET HPDFINFO AUTHOR TO 'Sistrom Sistemas Web'
      SET HPDFINFO CREATOR TO 'DFeMonitor/TMS.CLOUD v.' + appData:version
      SET HPDFINFO TITLE    TO HMG_UNICODE_TO_ANSI(::title)
      SET HPDFINFO SUBJECT     TO HMG_UNICODE_TO_ANSI(::subject)
      SET HPDFINFO KEYWORDS    TO HMG_UNICODE_TO_ANSI(::keyWords)
      SET HPDFINFO DATECREATED TO date() TIME time()
   endif
return ::success

method encoding() CLASS TCTeHPDFDoc
   SET HPDFDOC ENCODING TO "WinAnsiEncoding"
   //SET HPDFDOC ENCODING TO "UTF-8"   Dá pau!
return Nil

method pageHeader() CLASS TCTeHPDFDoc
   local target := ''
   // Cabeçalho Principal em todas as páginas
   // Formulário
   ::drawBox(2, 2, 20.5, 208)
   ::printLine(6, 2, 208)
   ::printLine(13, 2, 53)
   ::printLineVertical(6, 53, 20.5)
   ::printLineVertical(6, 100, 20.5)
   ::printLine(13, 100, 176)
   ::printLineVertical(6, 176, 20.5)
   ::printLine(21.5, 2, 205, true)
   ::setFont({'position' => 'CENTER', 'size' => 6, 'bold' => false})
   ::printText('DECLARO QUE RECEBI OS VOLUMES DESTE CONHECIMENTO EM PERFEITO ESTADO PELO QUE DOU POR CUMPRIDO O PRESENTE CONTRATO DE TRANSPORTE', 2.5, ::paper:center)
   ::font:Position := 'LEFT'
   ::printText('NOME', 6, 3)
   ::printText('RG', 13, 3)
   ::setFont({'position' => 'CENTER'})
   ::printText('ASSINATURA / CARIMBO', 17, 76)
   ::setFont({'position' => 'LEFT'})
   ::printText('TÉRMINO DA PRESTAÇÃO - DATA/HORA', 6, 101)
   ::printText('INÍCIO DA PRESTAÇÃO - DATA/HORA', 13, 101)
   ::setFont({'size' => 7, 'position' => 'CENTER', 'bold' => true})
   ::printText('CT-E', 6, 191)
   ::drawBox(22.5, 2, 58, 91)
   if hb_FileExists(::logotipo)
      if (Upper(token(::logotipo, '.')) == 'JPG')
         @ 23.5, 20 HPDFPRINT IMAGE ::logotipo WIDTH 45 HEIGHT 10 TYPE JPG
      elseif (Upper(token(::logotipo, '.')) == 'PNG')
         @ 23.5, 20 HPDFPRINT IMAGE ::logotipo WIDTH 45 HEIGHT 10 TYPE PNG
      endif
   endif
   ::setFont({'size' => 7})
   ::printText('N°. ' + ::nCT, 10, 191)
   ::printText('SÉRIE ' + ::serie, 14, 191)
   ::drawBox(22.5, 91, 43, 208)
   ::printLine(34, 91, 208)
   ::printLineVertical(22.5, 176, 76.5)
   ::setFont({'size' => 10, 'bold' => true})
   ::printText('DACTE', 23, 134)
   ::setFont({'size' => 8, 'bold' => false})
   ::printText('Documento Auxiliar do Conhecimento', 27, 134)
   ::printText('de Transporte Eletrônico', 30, 134)
   ::printText('MODAL', 23, ::center(176, 208))
   ::setFont({'size' => 7, 'bold' => false, 'position' => 'LEFT'})
   ::printText('MODELO', 34, 92)
   ::printLineVertical(34, 104, 43)
   ::printText('SÉRIE', 34, 106)
   ::printLineVertical(34, 116, 43)
   ::printText('NÚMERO', 34, 121)
   ::printLineVertical(34, 137, 43)
   ::printText('FL', 34, ::center(136, 147))
   ::printLineVertical(34, 148, 43)
   ::setFont({'size' => 6, 'bold' => false, 'position' => 'LEFT'})
   ::printText('DATA E HORA DE EMISSÃO', 34, 148)
   ::font:Size := 5
   ::printText('INSC. SUFRAMA DO DESTINATÁRIO', 34, 177)
   ::drawBox(58, 2, 76.5, 91)
   ::printLine(58, 91, 176)
   ::printLineVertical(58, 45, 76.5)
   ::setFont({'size' => 8, 'bold' => false, 'position' => 'CENTER'})
   ::printText('TIPO DO CTE', 58, ::center(2, 45))
   ::printText('TIPO DO SERVIÇO', 58, ::center(45, 90))
   ::setFont({'size' => 6, 'bold' => false, 'position' => 'LEFT'})
   ::printText('CHAVE DE ACESSO', 58, 92)
   ::printLine(67, 2, 176)
   ::printText('IND.DO CT-E GLOBALIZADO', 67.5, ::center(2, 45))
   ::printText('INF.DO CT-E GLOBALIZADO', 67.5, ::center(45, 91))
   ::setFont({'size' => 7, 'bold' => true, 'position' => 'LEFT'})
   ::drawBox(71.5, 10, 75, 13.5, false, ::indGlobalizado)
   ::printText('SIM', 72, 15)
   ::drawBox(71.5, 27, 75, 30.5, false, !::indGlobalizado)
   ::printText('NÃO', 72, 32)
   ::printText(::xObs_infGlobalizado, 72, ::center(45, 91))
   ::setFont({'size' => 8, 'bold' => false, 'position' => 'CENTER'})
   ::printText('Consulta em https://www.fazenda.sp.gov.br/cte', 70, ::center(91, 176))
   ::drawBox(76.5, 2, 85.5, 208)
   ::printLineVertical(76.5, ::paper:center, 85.5)
   ::font:Position := 'LEFT'
   ::printText('CFOP - NATUREZA DA PRESTAÇÃO', 77.5, 3)
   ::printText('PROTOCOLO DE AUTORIZAÇÃO DE USO', 77.5, ::paper:center + 1)
   ::drawBox(85.5, 2, 93.5, 208)
   ::printLineVertical(85.5, ::paper:center, 93.5)
   ::printText('INÍCIO DA PRESTAÇÃO', 86, 3)
   ::printText('TÉRMINO DA PRESTAÇÃO', 86, ::paper:center + 1)

   ::font:Size := 6
   ::drawBox(93.5, 2, 113, 208)
   ::printLineVertical(93.5, ::paper:center, 113)

   // Remetente
   ::printText('REMETENTE', 94.5, 3)
   ::printText('ENDEREÇO', 97.5, 3)
   ::printText('MUNICÍPIO', 103.5, 3)
   ::printText('CEP', 103.5, 87)
   ::printText('CNPJ/CPF', 106.5, 3)
   ::printText('INSCRIÇÃO ESTADUAL', 106.5, 60)
   ::printText('PAÍS', 109.5, 3)
   ::printText('FONE', 109.5, 78)

   // Destinatário
   ::printText('DESTINATÁRIO', 94.5, ::paper:center + 1)
   ::printText('ENDEREÇO', 97.5, ::paper:center + 1)
   ::printText('MUNICÍPIO', 103.5, ::paper:center + 1)
   ::printText('CEP', 103.5, ::paper:center + 85)
   ::printText('CNPJ/CPF', 106.5, ::paper:center + 1)
   ::printText('INSCRIÇÃO ESTADUAL', 106.5, ::paper:center + 58)
   ::printText('PAÍS', 109.5, ::paper:center + 1)
   ::printText('FONE', 109.5, ::paper:center + 76)

   // Dados - EMITENTE
   ::setFont({'size' => 8, 'bold' => true, 'position' => 'CENTER'})
   if len(::emi:nome) > 42
      target := SubStr(::emi:nome, hb_RAt(' ', ::emi:nome) + 1)
      ::emi:nome := Left(::emi:nome, hb_RAt(' ', ::emi:nome) - 1)
      do while len(::emi:nome) > 42 .and. (' ' $ ::emi:nome)
         target := SubStr(::emi:nome, hb_RAt(' ', ::emi:nome) + 1) + ' ' + target
         ::emi:nome := Left(::emi:nome, hb_RAt(' ', ::emi:nome) - 1)
      enddo
   endif
   ::printText(::emi:nome, 36, 46)
   ::printText(target, 39, 46)
   ::line := 43
   ::setFont({'size' => 7, 'bold' => false})
   ::printText(::emi:endereco + ' ' + ::emi:complemento,, 46)
   ::line += 3
   ::printText(::emi:bairro + ' - ' + ::emi:cep + ' - ' + ::emi:municipio + ' - ' + ::emi:uf,, 46)
   ::line += 3
   ::printText('Fone/Fax: ' + ::emi:fone,, 46)
   ::line += 4
   ::printText('CNPJ/CPF: ' + ::emi:doc + '   Insc.Estadual: ' + ::emi:ie,, 46)

   // Dados - InfCTe
   ::setFont({'size' => 10, 'bold' => true})
   ::printText(::modal, 27, ::center(176,208))
   ::setFont({'size' => 7, 'bold' => true, 'position' => 'CENTER'})
   ::printText(::mod, 38, ::center(91, 104))
   ::printText(::serie, 38, ::center(104, 116))
   ::printText(::nCT, 38, ::center(116, 136))
   ::printText(::getPag(), 38, ::center(136, 147))
   ::printText(::dhEmi, 38, ::center(147, 176))
   ::printText(::ISUF, 38, ::center(176, 208))
   ::printText(::tpCTe, 62, ::center(2, 45))
   ::printText(::tpServ, 62, ::center(45, 91))
   ::printText(Transform(::chCTe, '@R 9999.9999.9999.9999.9999.9999.9999.9999.9999.9999.9999'), 62, ::center(91, 176))
   ::setFont({'size' => 6, 'bold' => true, 'position' => 'LEFT'})
   ::printText(::cfop, 82, 3)
   ::font:Size := 7
   ::printText(::nProt, 82, ::paper:center + 1)
   ::printText(::iniPrest, 90, 3)
   ::printText(::fimPrest, 90, ::paper:center + 1)

   // Dados - REMENTENTE
   ::printText(Left(::rem:nome, 58), 94.5, 16)
   ::printText(::rem:endereco + ' ' + ::rem:complemento, 97.5, 16)
   ::printText(::rem:bairro, 100.5, 16)
   ::printText(::rem:municipio + ' - ' + ::rem:uf, 103.5, 16)
   ::printText(::rem:doc, 106.5, 16)
   ::printText(::rem:pais, 109.5, 16)
   ::font:Position := 'RIGHT'
   ::printText(::rem:cep, 103.5, 104)
   ::printText(::rem:ie, 106.5, 104)
   ::printText(::rem:fone, 109.5, 104)

   // Dados - DESTINATÁRIO
   ::font:Position := 'LEFT'
   ::printText(Left(::des:nome, 56), 94.5, ::paper:center + 17)
   ::printText(::des:endereco + ' ' + ::des:complemento, 97.5, ::paper:center + 17)
   ::printText(::des:bairro, 100.5, ::paper:center + 17)
   ::printText(::des:municipio + ' - ' + ::des:uf, 103.5, ::paper:center + 17)
   ::printText(::des:doc, 106.5, ::paper:center + 17)
   ::printText(::des:pais, 109.5, ::paper:center + 17)
   ::font:Position := 'RIGHT'
   ::printText(::des:cep, 103.5, 207)
   ::printText(::des:ie, 106.5, 207)
   ::printText(::des:fone, 109.5, 207)
   ::barCodes()
   ::setFont()
   ::qtdeDoc := 0
return Nil

method pageBody() class TCTeHPDFDoc
   if (::pagina == 1)
      // Expedidor
      ::drawBox(113, 2, 133, 208)
      ::printLineVertical(113, ::paper:center, 133)
      ::setFont({'size' => 6, 'bold' => false, 'position' => 'LEFT'})
      ::printText('EXPEDIDOR', 114, 3)
      ::printText('ENDEREÇO', 117, 3)
      ::printText('MUNICÍPIO', 123, 3)
      ::printText('CEP', 123, 87)
      ::printText('CNPJ/CPF', 126, 3)
      ::printText('INSCRIÇÃO ESTADUAL', 126, 60)
      ::printText('PAÍS', 129, 3)
      ::printText('FONE', 129, 78)
      // Recebedor
      ::font:Position := 'LEFT'
      ::printText('RECEBEDOR', 114, ::paper:center + 1)
      ::printText('ENDEREÇO', 117, ::paper:center + 1)
      ::printText('MUNICÍPIO', 123, ::paper:center + 1)
      ::printText('CEP', 123, ::paper:center + 85)
      ::printText('CNPJ/CPF', 126, ::paper:center + 1)
      ::printText('INSCRIÇÃO ESTADUAL', 126, ::paper:center + 58)
      ::printText('PAÍS', 129, ::paper:center + 1)
      ::printText('FONE', 129, ::paper:center + 76)
      // Tomador
      ::setFont({'size' => 6, 'bold' => false, 'position' => 'LEFT'})
      ::drawBox(133, 2, 144, 208)
      ::printText('TOMADOR', 134, 3)
      ::printText('MUNICÍPIO', 134, 120)
      ::printText('UF', 134, 171)
      ::printText('CEP', 134, ::paper:center + 85)
      ::printText('ENDEREÇO', 137, 3)
      ::printText('CNPJ/CPF', 140, 3)
      ::printText('INSCRIÇÃO ESTADUAL', 140, 60)
      ::printText('PAÍS', 140, ::paper:center + 50)
      ::printText('FONE', 140, ::paper:center + 76)
      // Produto Predominante
      ::setFont({'size' => 6, 'bold' => false, 'position' => 'LEFT'})
      ::drawBox(144, 2, 160.5, 208)
      ::printLine(152.5, 2, 208)
      ::printText('PRODUTO PREDOMINANTE', 145, 3)
      ::printLineVertical(144, 120, 160.5)
      ::printText('OUTRAS CARACTERÍSTICAS DA CARGA', 145, ::center(120, 165))
      ::printLineVertical(144, 167, 160.5)
      ::printText('VALOR TOTAL DA CARGA', 145, ::center(167, 208))
      ::printLineVertical(152.5, 40, 160.5)
      // PESOS, MEDIDAS E QTDE. VOLUMES
      ::setFont({'bold' => false, 'size' => 5, 'position' => 'CENTER'})
      ::printText('PESO BRUTO (KG)', 153, ::center(2, 40))
      ::printLineVertical(152.5, 78, 160.5)
      ::printText('PESO BASE CÁLCULO (KG)', 153, ::center(40, 78))
      ::printText('PESO AFERIDO (KG)', 153, ::center(78, 120))
      ::printText('CUBAGEM (M3)', 153, ::center(120, 164))
      ::printText('QTDE (VOL)', 153, ::center(164, 208))
      // COMPONENTES DO VALOR DA PRESTAÇÃO DO SERVIÇO
      ::drawBox(160.5, 2, 184.5, 208)
      ::printLine(164, 2, 208)
      ::printLineVertical(164, 55, 184.5)
      ::printLineVertical(164, 108, 184.5)
      ::printLineVertical(164, 161, 184.5)
      ::printLine(174, 161, 208)
      ::font:Size := 6
      ::printText('COMPONENTES DO VALOR DA PRESTAÇÃO DO SERVIÇO', 161, ::paper:center)
      ::font:Position := 'LEFT'
      ::line := 164.5
      ::column := 3
      ::printText('NOME')
      ::printText('NOME',, 56)
      ::printText('NOME',, 109)
      ::font:Position := 'RIGHT'
      ::printText('VALOR',, 53)
      ::printText('VALOR',, 106)
      ::printText('VALOR',, 159)
      ::printText('VALOR TOTAL DO SERVIÇO',, ::center(161, 208))
      ::printText('VALOR A RECEBER',175, ::center(161, 208))
      // INFORMAÇÕES RELATIVAS AO IMPOSTO
      ::drawBox(184.5, 2, 196.5, 208)
      ::printLine(188, 2, 208)
      ::printLineVertical(188, 70, 196.5)
      ::printLineVertical(188, 104, 196.5)
      ::printLineVertical(188, 140, 196.5)
      ::printLineVertical(188, 174, 196.5)
      ::printText('INFORMAÇÕES RELATIVAS AO IMPOSTO', 185, ::paper:center)
      ::font:Position := 'LEFT'
      ::printText('SITUAÇÃO TRIBUTÁRIA', 188.5, 3)
      ::printText('BASE DE CALCULO', 188.5, ::center(70, 104))
      ::printText('ALÍQUOTA ICMS', 188.5, ::center(104, 140))
      ::printText('VALOR ICMS', 188.5, ::center(140, 174))
      ::printText('% RED. BC ICMS', 188.5, ::center(174, 208))
      // DOCUMENTOS ORIGINÁRIOS
      ::drawBox(196.5, 2, 250, 208)
      ::printLine(200, 2, 208)
      ::printLineVertical(200, ::paper:center, 250)
      ::printText('DOCUMENTOS ORIGINÁRIOS', 197, ::paper:center)
      ::font:Position := 'LEFT'
      ::printText('TIPO DOC', 201, 3)
      ::printText('CNPJ/CHAVE/OBS', 201, ::center(2, ::paper:center - 6))
      ::font:Position := 'RIGHT'
      ::printText('SÉRIE/NRO. DOCUMENTO', 201, ::paper:center - 2)
      ::font:Position := 'LEFT'
      ::printText('TIPO DOC', 201, ::paper:center + 1)
      ::printText('CNPJ/CHAVE/OBS', 201, ::center(::paper:center, 202))
      ::font:Position := 'RIGHT'
      ::printText('SÉRIE/NRO. DOCUMENTO', 201, 202)
      // OBSERVAÇÕES
      ::drawBox(250, 2, 271, 208)
      ::printLine(253.5, 2, 208)
      ::font:Position := 'CENTER'
      ::printText('OBSERVAÇÕES', 250.5, ::paper:center)
      if (::tpAmb == '2')
         @ 263.5, 105 HPDFPRINT HMG_UNICODE_TO_ANSI('AMBIENTE DE HOMOLOGAÇÃO - SEM VALOR FISCAL') FONT ::font:Name SIZE 18 COLOR {129, 129, 129} CENTER
      endif
      // DADOS ESPECÍFICOS DO MODAL RODOVIÁRIO
      ::drawBox(271, 2, 281, 208)
      ::printText('DADOS ESPECÍFICOS DO MODAL RODOVIÁRIO', 271.5, ::paper:center)
      ::printLine(274.5, 2, 208)
      ::font:Position := 'LEFT'
      ::printText('RNTRC DA EMPRESA', 275, 3)
      ::printLineVertical(274.5, 30, 281)
      ::printText('ESTE CONHECIMENTO DE TRANSPORTE ATENDE À LEGISLAÇÃO DE TRANSPORTE RODOVIÁRIO EM VIGOR', 278, 32)
      // USO EXCLUSIVO DO EMISSOR DO CT-E
      ::drawBox(281, 2, 291, 150)
      ::drawBox(281, 150, 291, 208)
      ::printLine(284.5, 2, 208)
      ::printText('USO EXCLUSIVO DO EMISSOR DO CT-E', 281.5, ::center(2, 150))
      ::printText('RESERVADO AO FISCO', 281.5, ::center(150, 208))
      ::font:Position := 'LEFT'
   else
      // DOCUMENTOS ORIGINÁRIOS - Que não couberam na primeira página - Invocado para imprimir nas páginas "versos"
      ::setFont({'size' => 6, 'bold' => false, 'position' => 'LEFT'})
      ::drawBox(113, 2, 291, 208)
      ::printLine(116.5, 2, 208)
      ::font:Position := 'CENTER'
      ::printLineVertical(116.5, ::paper:center, 291)
      ::printText('DOCUMENTOS ORIGINÁRIOS', 113.5, ::paper:center)
      ::font:Position := 'LEFT'
      ::printText('TIPO DOC', 117.5, 3)
      ::printText('CNPJ/CHAVE/OBS', 117.5, ::center(2, ::paper:center - 6))
      ::font:Position := 'RIGHT'
      ::printText('SÉRIE/NRO. DOCUMENTO', 117.5, ::paper:center - 2)
      ::font:Position := 'LEFT'
      ::printText('TIPO DOC', 117.5, ::paper:center + 1)
      ::printText('CNPJ/CHAVE/OBS', 117.5, ::center(::paper:center, 202))
      ::font:Position := 'RIGHT'
      ::printText('SÉRIE/NRO. DOCUMENTO', 117.5, 202)
      ::setFont({'size' => 7, 'bold' => false, 'position' => 'LEFT'})
   endif

return Nil

method pageFooter() CLASS TCTeHPDFDoc
   ::setFont({'size' => 6, 'positon' => 'LEFT', 'bold' => false})
   ::printText('Impresso em ' + DToC(Date()) + ' ' + Time(), 293, 5)
   ::font:Position := 'RIGHT'
   ::printText('https://www.sistrom.com.br', 293, 203)
   //@ 293, 203 HPDFURLLINK 'SISTROM SISTEMAS WEB' TO 'https://www.sistrom.com.br' SIZE 6 FONT 'Times Roman' COLOR BLUE RIGHT
   ::pagina++
 return Nil

method setLine(line) CLASS TCTeHPDFDoc
   ::line := line
return Nil

method setColumn(column) CLASS TCTeHPDFDoc
   default column := 10
   ::column := column
return Nil

method setFont(params) CLASS TCTeHPDFDoc
   default params := {=>}
   ::font:Name := iif(hb_HGetDef(params, 'bold', false), 'Times-Bold', 'Times-Roman')
   ::font:Color := iif((::font:Name == 'Times-Bold'), {0, 0, 0}, {60, 60, 60})
   ::font:Size := hb_HGetDef(params, 'size', ::font:Size)
   ::font:Position := hb_HGetDef(params, 'position', ::font:Position)
return Nil

method printText(text, line, column, position) CLASS TCTeHPDFDoc
   default line := ::line
   default column := ::column
   default position := ::font:position
   if ::font:Name == 'default'
      if Empty(::font:Color)
         if position == 'RIGHT'
            @ line, column HPDFPRINT HMG_UNICODE_TO_ANSI(text) SIZE ::font:Size RIGHT
         elseif position == 'CENTER'
            @ line, column HPDFPRINT HMG_UNICODE_TO_ANSI(text) SIZE ::font:Size CENTER
         else
            @ line, column HPDFPRINT HMG_UNICODE_TO_ANSI(text) SIZE ::font:Size
         endif
      else
         if position == 'RIGHT'
            @ line, column HPDFPRINT HMG_UNICODE_TO_ANSI(text) SIZE ::font:Size COLOR BLACK RIGHT
         elseif position == 'CENTER'
            @ line, column HPDFPRINT HMG_UNICODE_TO_ANSI(text) SIZE ::font:Size COLOR BLACK CENTER
         else
            @ line, column HPDFPRINT HMG_UNICODE_TO_ANSI(text) SIZE ::font:Size COLOR BLACK
         endif
      endif
   else
      if Empty(::font:Color)
         if position == 'RIGHT'
            @ line, column HPDFPRINT HMG_UNICODE_TO_ANSI(text) FONT ::font:Name SIZE ::font:Size RIGHT
         elseif position == 'CENTER'
            @ line, column HPDFPRINT HMG_UNICODE_TO_ANSI(text) FONT ::font:Name SIZE ::font:Size CENTER
         else
            @ line, column HPDFPRINT HMG_UNICODE_TO_ANSI(text) FONT ::font:Name SIZE ::font:Size
         endif
      else
         if position == 'RIGHT'
            @ line, column HPDFPRINT HMG_UNICODE_TO_ANSI(text) FONT ::font:Name SIZE ::font:Size COLOR BLACK RIGHT
         elseif position == 'CENTER'
            @ line, column HPDFPRINT HMG_UNICODE_TO_ANSI(text) FONT ::font:Name SIZE ::font:Size COLOR BLACK CENTER
         else
            @ line, column HPDFPRINT HMG_UNICODE_TO_ANSI(text) FONT ::font:Name SIZE ::font:Size COLOR BLACK
         endif
      endif
   endif
   ::line := line
return Nil

method printLine(line, column, endColumn, dashedLine) CLASS TCTeHPDFDoc
   default line := ::line
   default column := ::column
   default endColumn := ::paper:right
   default dashedLine := false
   if dashedLine
      do while column < 208
         endColumn := column + 2
         @ line, column HPDFPRINT LINE TO line, endColumn PENWIDTH 0.1 COLOR BLACK
         column := endColumn + 1
      enddo
   else
      @ line, column HPDFPRINT LINE TO line, endColumn PENWIDTH 0.1 COLOR BLACK
   endif
return Nil

method printLineVertical(line, column, endLine) class TCTeHPDFDoc
   default line := ::line
   default column := ::column
   default endLine := line + 1
   @ line, column HPDFPRINT LINE TO endline, column PENWIDTH 0.1 COLOR BLACK
return Nil

method printBlockText(text, finalLine, endColumn, position) CLASS TCTeHPDFDoc
   default finalLine := ::line + 20
   default endColumn := ::paper:right
   default position := 'JUSTIFY'

   switch position
      case 'LEFT'
      @ ::line, ::column HPDFPRINT HMG_UNICODE_TO_ANSI(text) TO finalLine, endColumn
      exit
      case 'CENTER'
      @ ::line, ::column HPDFPRINT HMG_UNICODE_TO_ANSI(text) TO finalLine, endColumn CENTER
      exit
      case 'RIGHT'
      @ ::line, ::column HPDFPRINT HMG_UNICODE_TO_ANSI(text) TO finalLine, endColumn RIGHT
      exit
      case 'JUSTIFY'
      @ ::line, ::column HPDFPRINT HMG_UNICODE_TO_ANSI(text) TO finalLine, endColumn JUSTIFY
      exit
   endswitch

return Nil

method center(iniCol, fimCol) class TCTeHPDFDoc
   ::font:Position := 'CENTER'
return (fimCol - int((fimCol - iniCol) / 2))

method getPag class TCTeHPDFDoc
return hb_ntos(::pagina) + '/' + hb_ntos(::totPag)

method drawBox(startLine, startColumn, finalLine, endColumn, isRounded, isFilled) CLASS TCTeHPDFDoc
   default startLine := ::line
   default startColumn := ::column
   default finalLine := ::line + 5
   default endColumn := ::paper:right
   default isRounded := true
   default isFilled := false
   if isRounded
      if isFilled
         @ startLine, startColumn HPDFPRINT RECTANGLE TO finalLine, endColumn PENWIDTH 0.1 COLOR BLACK FILLED ROUNDED CURVE 1
      else
         @ startLine, startColumn HPDFPRINT RECTANGLE TO finalLine, endColumn PENWIDTH 0.1 COLOR BLACK ROUNDED CURVE 1
      endif
   else
      if isFilled
         @ startLine, startColumn HPDFPRINT RECTANGLE TO finalLine, endColumn PENWIDTH 0.1 COLOR BLACK FILLED
      else
         @ startLine, startColumn HPDFPRINT RECTANGLE TO finalLine, endColumn PENWIDTH 0.1 COLOR BLACK
      endif
   endif
return Nil

method barCodes() class TCTeHPDFDoc
   local codeImage128 := 'tmp\code128-' + ::chCTe + '.png'
   local codeImageQRCode := 'tmp\qrcode-' + ::chCTe + '.png'
   local bar_code, keyQRCode := 'https://nfe.fazenda.sp.gov.br/CTeConsulta/qrCode?chCTe=' + ::chCTe + '&tpAmb=' + ::tpAmb
   hb_FileDelete(codeImage128)
   hb_FileDelete(codeImageQRCode)
   bar_code := HMG_CreateBarCode(::chCTe,; // dígitos
                                 'CODE128',; // Tipo de codigo
                                 1,; // linhas width
                                 20,; // colunas height
                                 false,; // Imprimir os dítigos abaixo
                                 codeImage128,; // nome do arqruivo a ser salvo
                                 {0, 0, 0},; // cor das barras black
                                 {255, 255, 255},; // cor de fundo white
                                 true,;  // checksum
                                 false,;  // wide2_5
                                 false)  // wide3
   bar_code := HMG_CreateBarCode(keyQRCode,; // dígitos
                                 'QRCODE',; // Tipo de codigo
                                 2,; // linhas width
                                 110,; // colunas height
                                 false,; // Imprimir os dítigos abaixo
                                 codeImageQRCode,; // nome do arqruivo a ser salvo
                                 {0, 0, 0},; // cor das barras black
                                 {255, 255, 255},; // cor de fundo white
                                 true,;  // checksum
                                 false,;  // wide2_5
                                 false)  // wide3

   if hb_FileExists(codeImage128)
      @ 45.5, 94 HPDFPRINT IMAGE codeImage128 WIDTH 80 HEIGHT 10 TYPE PNG
   endif
   if hb_FileExists(codeImageQRCode)
      @ 48, 181 HPDFPRINT IMAGE codeImageQRCode WIDTH 24 HEIGHT 24 TYPE PNG
   endif
return Nil

method setdhCreated() class TCTeHPDFDoc
   GET HPDFINFO DATECREATED TO ::dhCreated
   ::dhCreated := "'" + Transform(::dhCreated, "@R 9999-99-99 99:99:99") + "'"
return ::dhCreated

method printDocsOriginarios(doc) class TCTeHPDFDoc
   ::qtdeDoc++ // Esse contador é zerado todas as vezes que o ::pageHeader() é invocado
   if ::qtdeDoc < 43
      // Preenche todo o lado esquerdo primeiro com até 40 linhas
      ::printText(doc['tpDoc'],, 3)
      ::printText(doc['descricao'],, ::center(2, ::paper:center - 6))
      ::font:Position := 'RIGHT'
      ::printText(doc['nDoc'],, ::paper:center - 2)
   else
      // Lado Direito de Docs Originários
      ::printText(doc['tpDoc'],, ::paper:center + 1)
      ::printText(doc['descricao'],, ::center(::paper:center, 202))
      ::font:Position := 'RIGHT'
      ::printText(doc['nDoc'],, 202)
   endif
   ::font:Position := 'LEFT'
   ::setLine(::getLine()+4)
return Nil

/* Classes auxiliares da classe TCTeHPDFDoc */
CLASS pdf_Font
   data Name init 'Times-Roman'
   data Size init 6
   data Color init BLACK
   data Position init 'LEFT'
end class

CLASS pdf_paper
   data size init 'A4'
   data orientation init 1
   data width init 210
   data lenth init 297
   data center init 105
   data right init 205
end class

class TCliente
   data nome init ''
   data endereco init ''
   data complemento init ''
   data bairro init ''
   data cep init ''
   data municipio init ''
   data uf init ''
   data fone init ''
   data doc init ''
   data ie init ''
   data pais init ''
end class

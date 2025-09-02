#include <hmg.ch>

// Criação do log do sistema em JSON

procedure saveLog(text, cLevel)
   local path := appData:systemPath + 'log\'
   local dateFormat := Set(_SET_DATEFORMAT, "yyyy.mm.dd")
   local logFile := 'dfeLog' + hb_ULeft(DToS(Date()),6) + '.json'
   local hLog := {"title" => '', "log" => {}}, log := {=>}
   local t, processos := ''
   local cFileContent := ""

   // Validação robusta do arquivo JSON existente
   if hb_FileExists(path + logFile)
      cFileContent := hb_MemoRead(path + logFile)
      if !Empty(cFileContent)
         hLog := hb_jsonDecode(cFileContent)
         // Verifica se o decode foi bem-sucedido e se tem a estrutura esperada
         if hLog == NIL .or. ValType(hLog) != "H"
            hLog := {"title" => '', "log" => {}}
         elseif !hb_HHasKey(hLog, "log") .or. ValType(hLog["log"]) != "A"
            // Se não tem a chave "log" ou não é array, recria
            hLog["log"] := {}
         endif
      endif
   endif

   // Garante que sempre temos a estrutura básica
   if !hb_HHasKey(hLog, "title") .or. Empty(hLog["title"])
      hLog["title"] := "Log de Sistema " + appData:displayName + " | " + GetMonthName(Month(Date())) + " DE " + hb_ntos(Year(Date()))
   endif

   default cLevel := "Information"

   log["version"] := appData:displayName
   log["date"] := DtoC(Date()) + ' ' + Time()
   log["level"] := cLevel

   if !Empty(ProcName(3))
      processos := ProcName(3) + '(' + hb_ntos(ProcLine(3)) + ')/'
   endif
   if !Empty(ProcName(2))
      processos += ProcName(2) + '(' + hb_ntos(ProcLine(2)) + ')/'
   endif

   processos += ProcName(1) + '(' + hb_ntos(ProcLine(1)) + ')'

   log["trace"] := processos

   if ValType(text) == 'A'
      log["messages"] := {}
      for each t in text
         if !(ValType(t) == 'C')
            if (ValType(t) == 'N')
               t := hb_ntos(t)
            elseif (ValType(t) == 'D')
               t := hb_DToC(t)
            elseif (ValType(t) == 'L')
               t := iif(t, 'true', 'false')
            endif
         endif
         AAdd(log["messages"], StrTran(t, "\", "/"))
      next
   elseif ValType(text) == "H"
      log["message"] := text
   else
      log["message"] := StrTran(text, "\", "/")
   endif

   // Validação final antes de adicionar
   if ValType(hLog["log"]) == "A"
      AAdd(hLog["log"], log)
      hb_MemoWrit(path + logFile, hb_jsonEncode(hLog, 4))
   else
      // Em caso de erro crítico, recria completamente
      hLog := {"title" => "Log de Sistema " + appData:displayName + " | " + GetMonthName(Month(Date())) + " DE " + hb_ntos(Year(Date())), "log" => {log}}
      hb_MemoWrit(path + logFile, hb_jsonEncode(hLog, 4))
   endif

   SET(_SET_DATEFORMAT, dateFormat)

return

/*
   Copiar esta função e usar em https://os.allcom.pl/harbour/
   para descriptar o texto.

function auxDecrypt(encrypted)
  local a := hb_ATokens(encrypted, "#|@")
  local L, texto := ""

  for each L in a
  	texto += chr(Val(L))
  next
return texto
*/
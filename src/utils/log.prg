#include <hmg.ch>

// Criação do log do sistema em JSON

procedure saveLog(text, cType)
   local path := appData:systemPath + 'log\'
   local dateFormat := Set(_SET_DATEFORMAT, "yyyy.mm.dd")
   local logFile := 'dfeLog' + hb_ULeft(DToS(Date()),6) + '.json'
   local hLog := {=>}, log := {=>}
   local t, processos := ''

   if hb_FileExists(path + logFile)
      hLog := hb_jsonDecode(hb_MemoRead(path + logFile))
   else
      hLog["title"] := "Log de Sistema " + appData:displayName + " | " + GetMonthName(Month(Date())) + " DE " + hb_ntos(Year(Date()))
      hLog["log"] := {}
   endif

   default cType := "Information"

   log["version"] := appData:displayName
   log["date"] := DtoC(Date()) + ' ' + Time()
   log["type"] := cType

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
   else
      log["message"] := StrTran(text, "\", "/")
   endif

   AAdd(hLog["log"], log)
   hb_MemoWrit(path + logFile, hb_jsonEncode(hLog, 4))
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
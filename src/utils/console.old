#include "hmg.ch"
#include <fileio.ch>

procedure consoleLog(text)
   local path := appData:systemPath + 'log\'
   local dateFormat := Set(_SET_DATEFORMAT, "yyyy.mm.dd")
   local logFile := 'console' + hb_ULeft(DToS(Date()),6) + '.log'
   local h, n := 0
   local t, msg := "", processos := ''

   if hb_FileExists(path + logFile)
      h := FOpen(path + logFile, FO_WRITE)
      FSeek(h, 0, FS_END)
   else
      h := hb_FCreate(path + logFile, FC_NORMAL)
      FWrite(h, 'Console Log de Sistema ' + appData:displayName + hb_eol() + hb_eol())
   endif
   if ValType(text) == 'A'
      for each t in text
         n++
         if !(ValType(t) == 'C')
            if (ValType(t) == 'N')
               t := hb_ntos(t)
            elseif (ValType(t) == 'D')
               t := hb_DToC(t)
            elseif (ValType(t) == 'L')
               t := iif(t, 'true', 'false')
            else
               t := "Parametro t is null | Posicao: " + hb_ntos(n)
            endif
         endif
         msg += t
      next
   elseif ValType(text) == 'N'
      msg := hb_ntos(text)
   elseif ValType(text) == 'D'
      msg := DtoC(text)
   else
      msg := text
   endif

   if !Empty(ProcName(3))
      processos := ProcName(3) + '(' + hb_ntos(ProcLine(3)) + ')->'
   endif
   if !Empty(ProcName(2))
      processos += ProcName(2) + '(' + hb_ntos(ProcLine(2)) + ')->'
   endif

   processos += ProcName(1) + '(' + hb_ntos(ProcLine(1)) + ')'

   msg := DtoC(Date()) + ' ' + Time() + ' [' + processos + ']' + hb_eol() + "    " + msg + hb_eol() + hb_eol()

   Set(_SET_DATEFORMAT, dateFormat)

   FWrite(h, msg)
   FClose(h)

return

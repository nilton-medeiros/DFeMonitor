function firstString(cString)
    local pos as numeric

   if !Empty(cString)
       cString := AllTrim(cString)
       pos := hb_uAt(' ', cString)
       if (pos == 0)
         pos := hmg_len(cString)
       endif
       cString := hb_ULeft(cString, pos)
    endif
    
return cString

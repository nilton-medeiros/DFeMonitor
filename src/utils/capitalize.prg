#include "hmg.ch"

Function Capitalize(cString)
    Local nPos

    cString := AllTrim(cString)
    cString := Hmg_Upper(hb_ULeft(cString,1)) + Hmg_Lower(hb_USubStr(cString, 2))
    cString := hb_Utf8StrTran(cString, " ", Chr(176))
    nPos    := hb_UAt(Chr(176), cString)

    do while nPos > 0
        cString := hb_ULeft(cString, nPos-1) + " " + Hmg_Upper(hb_USubStr(cString, nPos+1 , 1)) + hb_USubStr(cString, nPos+2)
        nPos := hb_UAt(Chr(176), cString)
    enddo

Return cString

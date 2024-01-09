#include "hmg.ch"

/*
function date_as_string(date)
    default date := Date()
return Transform(DToS(date), "@R 9999-99-99")
 */

function string_as_DateTime(stringDate, lTDZ)
    default lTDZ := false
return StrTran(stringDate, " ", "T") + iif(lTDZ, appData:utc, "")

function ansi_to_unicode(string)
return hmg_ansi_to_unicode(AllTrim(string))

function unicode_to_ansi(string)
return hmg_unicode_to_ansi(mysql_escape_string(AllTrim(string)))

function date_as_DateTime(date, LTDZ, lWithT)
    local result
    default date := Date()
    default lTDZ := false
    default lWithT := true
    if lWithT
        result := Transform(DToS(date), "@R 9999-99-99") + "T" + Time() + iif(lTDZ, appData:utc, "")
    else
        result := Transform(DToS(date), "@R 9999-99-99") + " " + Time() + iif(lTDZ, appData:utc, "")
    endif
return result

function number_format(number, decimal)
    local format := "99999999999"

    default decimal := 0

    if (Valtype(number) == "C")
        number := Val(AllTrim(number))
    endif
    if !(decimal == 0)
        format += "." + Replicate("9", decimal)
    endif
return Val(LTrim(Transform(number, format)))

function ConvertUTCdataStampToLocal(cDateTime)
    local datetime, dtNew

    SET DATE ANSI
    datetime := hb_CtoT(DateTime_to_mysql(cDateTime))
    dtNew := datetime - TimeDelta(0, 3, 0, 0)
    cDateTime := DateTime_to_mysql(hb_TSToStr(dtNew))
    SET DATE BRITISH

return cDateTime

function TimeDelta(days, hours, minutes, seconds)
    IF days > 0
        days := ((days * 24) * 60 ) / (24 * 60)
    ENDIF

    IF hours > 0
        hours := (hours * 60 ) / (24 * 60)
    ENDIF

    IF minutes > 0
        minutes := minutes / (24 * 60)
    ENDIF

    IF seconds > 0
        seconds := (seconds / 60) / (24 * 60)
    ENDIF

RETURN days + hours + minutes + seconds

#include "hmg.ch"

procedure TextBox_onGoToFocus(form, controler)
    SetProperty(form, controler, "BackColor", {190, 215, 250})
    return

procedure TextBox_onLostFocus(form, controler, format)
    local charNumber

    SetProperty(form, controler, "BackColor", WHITE)

    if ValType(format) == "C"
        charNumber := getNumbers(GetProperty(form, controler, "value"))
        if !Empty(charNumber) .and. hmg_len(charNumber) == hmg_len(getNumbers(format))
            SetProperty(form, controler, "value", Transform(charNumber, format))
        endif
    endif

    return
#define false .F.

function isTrue(boolean)
    local res

    switch valtype(boolean)
        case "L"
            res := boolean
            exit
        case "N"
            res := (boolean > 0)
            exit
        case "C"
            res := !Empty(boolean)
            exit
        case "A"
            res := (hmg_len(boolean) > 0)
            exit
        case "O"
            res := !Empty(boolean)
            exit
        otherwise
            res := false
    endswitch

return res

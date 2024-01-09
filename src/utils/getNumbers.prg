function getNumbers(string)
    local charNumbers := ""
    local char

    if ValType(string) == "C" .and. !Empty(string)
        for each char in string
            if (char $ "0123456789")
                charNumbers += char
            endif
        next
    endif

return charNumbers

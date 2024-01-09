// Função não usada na compilação, substituido por apenas hb_jsonDecode(text) sem var ref. @jsonHash

function jsonDecode(text)
    local bytes, jsonHash
    bytes := hb_jsonDecode(text, @jsonHash)
    if (bytes == 0)
        jsonHash := {}
    endif
return jsonHash
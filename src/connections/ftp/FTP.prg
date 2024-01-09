#include "hbclass.ch"

// TFTP Class: Apenas uma sacola de dados, classe anêmica funcionando mais como uma interface

class TFTP
    data url readonly
    data urlFiles readonly
    data server readonly
    data user readonly
    data password readonly
    method new(url, server, user, password) constructor
end class

method new(url, server, user, password) class TFTP
    ::url := iif(ValType(url) == "C", AllTrim(url), "")
    ::server := iif(ValType(server) == "C", AllTrim(server), "")
    ::user := iif(ValType(user) == "C", AllTrim(user), "")
    ::password := iif(ValType(password) == "C", password, "")
    ::urlFiles := "https://www" + SubStr(::server, 4) + "/"
return self

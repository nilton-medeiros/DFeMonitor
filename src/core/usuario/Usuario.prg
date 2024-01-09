#include "hmg.ch"
#include "hbclass.ch"

class TUsuario

    data id readonly
    data login readonly
    data password readonly

    method new(user) constructor

end class

method new(user) class TUsuario
    ::id := user['id']
    ::login := user['login']
    ::password := user['password']
return self

#include "hmg.ch"

Procedure SysWait(nWait)
    Local iTime := Seconds()

        DEFAULT nWait := .1

        Do While Seconds() - iTime < nWait
            DO EVENTS
        EndDo

    Return

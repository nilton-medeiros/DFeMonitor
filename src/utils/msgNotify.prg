#include "hmg.ch"

procedure msgNotify(msgNtfy)
    local notifyTooltip, showMsg

    with object memvar->appDataSource

       if !hb_isHash(msgNtfy)
          if :connected
             :connectionStatus := 'Conectado'
          else
             :connectionStatus := 'Desconectado'
          endif
          if (ValType(msgNtfy) == 'C') .and. !Empty(msgNtfy)
              msgNtfy := {'notifyTooltip' => :connectionStatus, 'showMsg' => msgNtfy}
          else
              msgNtfy := {'notifyTooltip' => :connectionStatus, 'showMsg' => ''}
          endif
       endif

       notifyTooltip := hb_HGetDef(msgNtfy, 'notifyTooltip', :connectionStatus)
       showMsg := hb_HGetDef(msgNtfy, 'showMsg', '')

       if isWIndowActive(setup)
          SetProperty("setup", "StatusBar", "Item", 1, "Database: " + :dataBase + " | " + notifyTooltip)
          SetProperty("setup", "StatusBar", "Item", 2, :connectionStatus)
          SetProperty("setup", "StatusBar", "Icon", 2, :iconStatus)
       endif

       memvar->appData:lastMessage := notifyTooltip
       SetProperty('main', 'notifyTooltip', memvar->appData:displayName + hb_eol() + notifyTooltip)

       if !Empty(showMsg)
          if :connected
             MsgExclamation(showMsg['message'], "DFeMonitor " + appData:version + ": " + showMsg['title'])
          else
             MsgStop(showMsg['message'], "DFeMonitor " + appData:version + ": " + showMsg['title'])
          endif
       endif
    end

 return

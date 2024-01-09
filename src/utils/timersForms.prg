#define true .T.
#define false .F.

// Inicializa o Timer do Form principal main
procedure startTimer()
    SetProperty("main", "Timer_DFE", "Enabled", true)
return

// Paraliza o Timer do Form principal main
procedure stopTimer()
    SetProperty("main", "Timer_DFE", "Enabled", false)
return

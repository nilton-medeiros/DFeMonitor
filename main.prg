
#require "hbwin"
#include <hmg.ch>
#include <fileio.ch>

REQUEST HB_CODEPAGE_UTF8

/*
    DFeMonitor: Roda como um serviço minimizado na taskbar do Windows, monitora os DFes de um grupo de empresas
                transportadoras para emitir CTes (4.00) e MDFes, faz Autorização, Cancelamento, Carta de Correção e
                obtem XMLs/PDFs junto a Rest API da Nuvem Fiscal. Gera DACTE em PDF com layout mais apresentável.
    main: Inicializa o programa, mas é na main_form_oninit() que realmente faz toda a configuração inicial.
        * Nesta aplicação: Todos os objetos públicos começam com "app", são utilizados em toda a aplicação
        appData:        Contém configurações gerais e iniciais da aplicação, cria e atualiza o RegEdit do Windows.
        appDataSource:  Utilizada em qualquer rotina que necessite se conectar ao backend (banco de dados).
        appFTP:         Utilizada pelas rotinas de GED (Gerenciamento Eletrônico de Documentos),
                        faz upload e download de arquivos como xml/pdf,etc de<->para nuvem (S3/Locaweb/etc).
        appEmpresas:    Recebe todas as empresas emitentes de CTe/MDFe na inicialização do aplicativo.
        appUsuarios:    Recebe todos os usuários admin de cada empresa que podem alterar parâmetros de monitoração
                        e outras configurações no form setup do aplicaitvo.
        appNuvemFiscal: Faz a autenticação e disponibiliza integração com a RestAPI da Nuvem Fiscal
        links: sistrom.com.br, nuvemfiscal.com.br
*/
Function Main

    public appData := TAppData():new("4.1.35")
    public appDataSource
    public appFTP
    public appEmpresas
    public appUsuarios
    public appNuvemFiscal

    IF HMG SUPPORT UNICODE RUN

    hb_langSelect("PT")
    hb_cdpSelect("UTF8")

    SET CODEPAGE TO UNICODE
    SET LANGUAGE TO PORTUGUESE
    SET MULTIPLE OFF
    SET TOOLTIPSTYLE BALLOON
    SET NAVIGATION EXTENDED
    SET DATE BRITISH
    SET CENTURY ON
    SET EPOCH TO Year(date()) - 20

    appData:registerSystem()

    Load Window Main
    Main.Center
    Main.Activate

return

procedure about()
    ShellAbout(;
        "DFeMonitor",;
        "Monitoramento de DFes emitidos pelo sistema web TMS.CLOUD " +;
        appData:version + hb_eol() + Chr(169) + ;
        " by Sistrom Sistemas Web, 2010-" + hb_ntos(year(date())) + " | suporte@sistrom.com.br",;
        LoadTrayIcon(GetInstance(), "main");
    )
return

procedure main_form_oninit()
    local dbServer, dbUser, dbPassword, dbPort, dbDatabase
    local ftpUrl, ftpServer, ftpUser, ftpPassword
    local empresa

    // Paraliza o timer de monitoramento enquanto faz as configurações iniciais
    StopTimer()

    if (win_regRead(appData:winRegistryPath + "Monitoring\DontRun") == 1)
        saveLog("Parada forçada: O parâmetro DontRun está ativo")
        MessageBoxTimeout("O parâmetro DontRun está ativo!", "DFeMonitor " + appData:version + ": Parada forçada", MB_ICONEXCLAMATION, 5000)
        turnOFF()
    endif

    with object appData

        :registerDatabase()

        /*
            Substituição do translado da função RegistryRead() pela real função win_regRead()
            Por motivo que eu desconheço, a função RegistryRead() aqui no main.prg, nesta aplicação
            não é reconhecida pelo compilador, da erro de compilação, tentei de tudo, o
            #include 'hmg.ch' está ok, tanto que curiosamente a função RegistryWrite() é reconhecida
            pela compilação neste main.prg.
        */
        dbServer := CharXor(win_regRead(:winRegistryPath + "Host\db_ServerName"), "SysWeb2023")
        dbUser := CharXor(win_regRead(:winRegistryPath + "Host\db_UserName"), "SysWeb2023")
        dbPassword := CharXor(win_regRead(:winRegistryPath + "Host\db_Password"), "SysWeb2023")
        dbPort := CharXor(win_regRead(:winRegistryPath + "Host\db_Port"), "SysWeb2023")
        dbDatabase := CharXor(win_regRead(:winRegistryPath + "Host\db_Database"), "SysWeb2023")

        ftpUrl := CharXor(win_regRead(:winRegistryPath + "Host\ftp_url"), "SysWeb2023")
        ftpServer := CharXor(win_regRead(:winRegistryPath + "Host\ftp_server"), "SysWeb2023")
        ftpUser := CharXor(win_regRead(:winRegistryPath + "Host\ftp_user"), "SysWeb2023")
        ftpPassword := CharXor(win_regRead(:winRegistryPath + "Host\ftp_password"), "SysWeb2023")

    endwith

    appDataSource := TMySQLDataSource():new(dbServer, dbUser, dbPassword, dbPort, dbDatabase)
    appFTP := TFTP():new(ftpUrl, ftpServer, ftpUser, ftpPassword)

    if appDataSource:connect()

        appEmpresas := TDbEmpresas():new()

        if !appEmpresas:ok
            saveLog("Nenhuma empresa foi retornada do banco de dados", "Warning")
            MessageBoxTimeout('Nenhuma empresa foi retornada do banco de dados' + hb_eol() + 'Avise ao suporte!', "DFeMonitor " + appData:version + ": Parada forçada", MB_ICONEXCLAMATION, 300000)
            turnOFF()
        endif

        appNuvemFiscal := TAuthNuvemFiscal():new()

        if !appNuvemFiscal:Authorized
            turnOFF()
        endif

        appUsuarios := TDbUsuarios():new()

        if !appUsuarios:ok
            // A falta de usuários administradores não interfere no monitoramento de CT-es, apenas o Setup não será liberado
            saveLog("Nenhum usuario admin foi retornado do banco de dados")
        endif

    else
        turnOFF()
    endif

    // Executa a cada vez que o sistema é iniciado, mais ou menos a cada 24hs
    for each empresa in appEmpresas:empresas
        // Para cada empresa, verifica se já tem cadastrou ou alterar algo em Nuvem Fiscal
        if empresa:nuvemfiscal_cadastrar
            cadastrarEmpresa(empresa)
        elseif empresa:nuvemfiscal_alterar
            alterarEmpresa(empresa)
        endif
    next

    SetProperty("main", "notifyIcon", "serverON")
    MessageBoxTimeout("O DFeMonitor ficará oculto na barra de tarefa", "DFeMonitor " + appData:version + ": Inicializado", MB_ICONEXCLAMATION, 3000)
    recoverySQL()
    startTimer()

return

// Monitoramento: Essa procedure é invodada pelo timer em main.fmg conforme intervalo estabelecido no timer: 10 segundos
procedure main_Timer_dfe_action()
    local timeHHMM := hb_ULeft(Time(), 5)
    local timerStart := appData:timerStart
    local timerEnd := appData:timerEnd
    local nSeconds, nTimeElapsed

    /*
        Paraliza o Timer do form principal main para que as rotinas de monitoramento não
        não sejam chamadas novamente (encavale) enquanto elas estão em execução, o tempo de execução
        depende da quantidade de CTes e MDFes a serem processados
    */
    stopTimer()

    if IsWindowActive(setup)
        appData:setTimer()
        return
    endif

    if (win_regRead(appData:winRegistryPath + "Monitoring\Stop_Execution") == 1)
        saveLog("Parada forçada para atualização")
        turnOFF()
    endif

    // timerStart e timerEnd são período de inatividade definido pelos usuários admins em setup form
    if (timerStart < timerEnd)
        // Inatividade dentro do mesmo dia
        if (timeHHMM >= timerStart) .and. (timeHHMM <= timerEnd)
            // Período de inatividade ativo, não faz monitoramento de CTes/MDFes
            appData:setTimer()  // Reseta o timer para mais 10 segundos...
            startTimer()
            return
        endif
    else
        // Inatividade de um dia para o outro
        if (timeHHMM >= timerStart .and. timeHHMM <= "23:59") .or. (timeHHMM >= "00:00" .and. timeHHMM <= timerEnd)
            // Período de inatividade ativo entre antes da meia noite e madrugada, não faz monitoramento de CTes/MDFes
            appData:setTimer()
            startTimer()
            return
        endif
    endif

    // Monitoramento de CTes e MDFes conforme a frequência estabelecida em frequency
    nSeconds := Seconds()
    nTimeElapsed := nSeconds - appData:timer

    if (nTimeElapsed >= appData:frequency)
        if appNuvemFiscal:ChecksTokenExpired()
            // saveLog("Tempo decorrido: " + hb_ntos(nTimeElapsed) + " | Frequência: " + hb_ntos(appData:frequency))
            cteMonitoring()
            mdfeMonitoring()
        else
            saveLog("Não foi possível receber o novo token de acesso à NuvemFiscal, verifique o apiLog")
            turnOFF()
        endif
        appData:setTimer()
    endif

    startTimer()

return

procedure turnOFF(isUser)
    default isUser := false

    stopTimer()
    if !Empty(appDataSource)
        appDataSource:disconnect()
    endif

    if isUser
       saveLog('Sistema encerrado pelo usuário')
    else
       saveLog('Sistema encerrou a execução')
    endif
    RegistryWrite(appData:winRegistryPath + "Monitoring\Running", 0)
    RELEASE WINDOW ALL

return

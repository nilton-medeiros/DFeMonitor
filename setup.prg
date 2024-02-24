#include "hmg.ch"
#include <fileio.ch>

#define GREEN_OCRE {0, 128, 128}
#define YELLOW_OCRE {253, 253, 0}

procedure setup()
	private cbxUsers AS OBJECT
	private REGISTRY_PATH

	if isWindowActive(setup)
		doMethod('setup', 'setFOCUS')
	else
		LOAD WINDOW setup
		ON KEY ESCAPE OF setup ACTION setup.RELEASE
		setup.CENTER
		setup.ACTIVATE
	endif
return

procedure setup_form_oninit()
	local empresa AS OBJECT
	local usuario AS HASH
	local notifyTooltip := hb_utf8StrTran(appData:lastMessage, hb_eol(), " | ")
	local tmp

    stopTimer()

	DoMethod( 'setup', 'Grid_Empresas', "DeleteAllItems" )

    for each empresa in appEmpresas:empresas
		DoMethod('setup', 'Grid_Empresas', "AddItem", {empresa:id, empresa:xNome, iif(empresa:tpAmb == 1,'Produção', 'Homologação')})
    next

	SetProperty('setup', 'Tab_Setup', 'value', 1)
	SetProperty('setup', 'Grid_Empresas', 'value', 1)

	cbxUsers := TComboBox():new('setup', 'Combo_Users')

    for each usuario in appUsuarios:usuarios
        cbxUsers:AddItem(usuario:login, usuario:password)
    next

    cbxUsers:setValue(1)

    SetProperty('setup', 'Text_seconds', 'Value', appData:frequency)
    SetProperty('setup', 'Text_das', 'Value', appData:timerStart)
    SetProperty('setup', 'Text_as', 'Value', appData:timerEnd)
    SetProperty('setup', 'Text_path_xml_pdf', 'Value', appData:dfePath)
	SetProperty("setup", "ProgressBar_Transmitindo", "visible", false)
	SetProperty("setup", "ProgressBar_Transmitindo", "enabled", false)
	SetProperty("setup", "ProgressBar_Transmitindo", "value", 50)
	SetProperty("setup", "StatusBar", "Item", 1, "Database: " + notifyTooltip)
    SetProperty("setup", "StatusBar", "Item", 2, appDataSource:connectionStatus)
    SetProperty("setup", "StatusBar", "Icon", 2, appDataSource:iconStatus)

	// Buttons
	SetProperty('setup', 'Button_Submit_Certificado', 'Enabled', false)
	SetProperty('setup', 'Button_Submit_Logotipo', 'Enabled', false)

return

procedure showPassword_action()
	SetProperty('setup', 'Text_Password', 'visible', false)
	SetProperty('setup', 'Label_showPassword', 'Visible', true)
	SetProperty('setup', 'Label_showPassword', 'Value', GetProperty('setup', 'Text_Password', 'Value'))
	Inkey(2)
	SetProperty('setup', 'Label_showPassword', 'Visible', false)
	SetProperty('setup', 'Text_Password', 'visible', true)
return

procedure setup_text_seconds_onLostFocus()
	if (GetProperty('setup', 'Text_seconds', 'Value') < 5)
		SetProperty('setup', 'Text_seconds', 'Value', 5)
	endif
	TextBox_onLostFocus("setup", "Text_seconds")
return

procedure setup_text_das_onLostFocus()
	if (GetProperty('setup', 'Text_das', 'Value') < "00:00") .or. (GetProperty('setup', 'Text_das', 'Value') > "23:59")
		SetProperty('setup', 'Text_das', 'Value', '  :  ')
	endif
	TextBox_onLostFocus("setup", "Text_das")
return

procedure setup_text_as_onLostFocus()
	if (GetProperty('setup', 'Text_as', 'Value') < "00:00") .or. (GetProperty('setup', 'Text_as', 'Value') > "23:59")
		SetProperty('setup', 'Text_as', 'Value', '  :  ')
	endif
	TextBox_onLostFocus("setup", "Text_as")
return

procedure setup_button_save_action()
	local dfePath := GetProperty('setup', 'Text_path_xml_pdf', 'Value')
	local fileLogo := GetProperty('setup', 'Image_logotipo', 'picture')

    if empty(dfePath)
		MsgExclamation('Definir a pasta raiz dos XMLs & PDFs', "DFeMonitor " + appData:version)
        return
    endif
	if !hb_DirExists(dfePath) .and. !hb_DirBuild(dfePath)
		MsgExclamation('Pasta para armazenar os XMLs e PDFs dos DFEs inválida, não pode ser criada', "DFeMonitor " + appData:version + ": Pasta de DFEs")
        return
	endif

	if GetProperty('setup', 'Text_seconds', 'Value') < 10
		SetProperty('setup', 'Text_seconds', 'Value', 10)
	endif

    if (GetProperty('setup', 'Text_password', 'Value') == cbxUsers:getCargo())
        appData:setDfePath(dfePath)
        RegistryWrite(appData:winRegistryPath + "InstallPath\dfePath", appData:dfePath)
        RegistryWrite(appData:winRegistryPath + "Monitoring\TimerStart", GetProperty('setup', 'Text_das', 'Value'))
        RegistryWrite(appData:winRegistryPath + "Monitoring\TimerEnd", GetProperty('setup', 'Text_as', 'Value'))
        RegistryWrite(appData:winRegistryPath + "Monitoring\frequency", GetProperty('setup', 'Text_seconds', 'Value'))
        saveLog('Usuario ' + cbxUsers:getDisplay() + ' alterou campos do setup')
        doMethod('setup', 'RELEASE')
	else
		MsgExclamation('Senha Inválida para o usuário ' + cbxUsers:getDisplay() + "!", "DFeMonitor " + appData:version + ': Senha')
	endif

return

procedure setup_button_cancel_action()
	doMethod('setup', 'RELEASE')
return

procedure setup_button_turnOFF_action()
	if MsgYesNo("Deseja interromper o monitoramento de DFEs?", 'DFeMonitor: Desligar')
		turnOFF(true)
	endif
return

procedure setup_form_onrelease()
	startTimer()
return

procedure setup_Grid_Empresas_onChange()
	local index := GetProperty("setup", "Grid_Empresas", "value")
	local msgUpload, empresa

	if (index == 0)
		REGISTRY_PATH := appData:winRegistryPath + "nuvemFiscal\Emp0\"
	else
		empresa := appEmpresas:empresas[index]
		REGISTRY_PATH := appData:winRegistryPath + "nuvemFiscal\Emp" + hb_ntos(empresa:id) + "\"
		// Certificado
		if  (RegistryRead(REGISTRY_PATH + "certificado\nome_razao_social") == NIL)
			RegistryWrite(REGISTRY_PATH + "certificado\nome_razao_social", empresa:xNome)
			RegistryWrite(REGISTRY_PATH + "certificado\cnpj", empresa:CNPJ)
			RegistryWrite(REGISTRY_PATH + "certificado\subject_name", "")
			RegistryWrite(REGISTRY_PATH + "certificado\issuer_name", "")
			RegistryWrite(REGISTRY_PATH + "certificado\serial_number", "")
			RegistryWrite(REGISTRY_PATH + "certificado\validity_period", "")
			RegistryWrite(REGISTRY_PATH + "certificado\expires_in", "")
			RegistryWrite(REGISTRY_PATH + "certificado\upladed", 0)
			RegistryWrite(REGISTRY_PATH + "certificado\CertFile", "")
			SetProperty('setup', 'Text_RazaoSocial', 'value', empresa:xNome)
			SetProperty('setup', 'Text_CNPJ', 'value', empresa:CNPJ)
			SetProperty('setup', 'Text_RazaoSocial_logotipo', 'value', empresa:xNome)
			SetProperty('setup', 'Text_CNPJ_logotipo', 'value', empresa:CNPJ)
			SetProperty('setup', 'Text_ArquivoPFX', 'value', "")
		else
			SetProperty("setup", "Text_RazaoSocial", "value", RegistryRead(REGISTRY_PATH + "certificado\nome_razao_social"))
			SetProperty("setup", "Text_CNPJ", "value", RegistryRead(REGISTRY_PATH + "certificado\cnpj"))
			SetProperty("setup", "Text_RazaoSocial_logotipo", "value", empresa:xNome)
			SetProperty("setup", "Text_CNPJ_logotipo", "value", empresa:CNPJ)
			SetProperty("setup", "Text_Assunto", "value", RegistryRead(REGISTRY_PATH + "certificado\subject_name"))
			SetProperty("setup", "Text_Emissor", "value", RegistryRead(REGISTRY_PATH + "certificado\issuer_name"))
			SetProperty("setup", "Text_Serie", "value", RegistryRead(REGISTRY_PATH + "certificado\serial_number"))
			SetProperty("setup", "Text_Validade", "value", RegistryRead(REGISTRY_PATH + "certificado\validity_period"))
			SetProperty('setup', 'Text_ArquivoPFX', 'value', RegistryRead(REGISTRY_PATH + "certificado\CertFile"))
		endif

		// logotipo
		if (RegistryRead(REGISTRY_PATH + "logotipo\LogoFile" ) == NIL)
			RegistryWrite(REGISTRY_PATH + "logotipo\LogoFile", "")
			RegistryWrite(REGISTRY_PATH + "logotipo\uploaded", 0)
		else
			SetProperty("setup", "Image_logotipo", "picture", RegistryRead(REGISTRY_PATH + "logotipo\LogoFile"))
			if Empty(RegistryRead(REGISTRY_PATH + "logotipo\uploaded"))
				msgUpload := "Logotipo não enviado para DACTE"
			else
				msgUpload := "Logotipo enviado para DACTE"
			endif
			SetProperty("setup", "Label_StatusLogotipo", "value", msgUpload)
		endif

	endif

	if Empty(GetProperty('setup', 'Image_logotipo', 'picture')) .or. (RegistryRead(REGISTRY_PATH + "logotipo\uploaded") == 0)
		SetProperty('setup', 'Button_Delete_Logotipo', 'Enabled', false)
	else
		SetProperty('setup', 'Button_Delete_Logotipo', 'Enabled', true)
	endif

	SetProperty('setup', 'Button_Submit_Logotipo', 'Enabled', !Empty(GetProperty('setup', 'Image_logotipo', 'picture')))

return

procedure setup_button_arquivopfx_action()
	local filePFX := GetFile({{'Arquivos PFX (*.PFX,*.P12)', '*.pfx;*.p12'}}, 'Selecione o Certificado', 'certificados')
	SetProperty('setup', 'Text_ArquivoPFX', 'value', filePFX)
	SetProperty('setup', 'Button_Submit_Certificado', 'Enabled', !Empty(filePFX))
return

procedure setup_button_logotipo_action()
	local fileLogo := GetFile({{'Logotipos (*.PNG,*.JPG,*.JPEG)', '*.png;*.jpg;*.jpeg'}}, 'Selecione um Logotipo', 'Logotipos')
	local nSize := hb_FSize(fileLogo)
	if (nSize > 204800)
		nSize := nSize / 1024
		MsgExclamation({"Tamanho do logotipo maior que permitido!", hb_eol(), "Tamanho: " + hb_ntos(nSize) + " KB", hb_eol(), "Pemitido até: 200 KB"}, "DFeMonitor " + appData:version + ": Logotipo Recusado")
	else
		SetProperty('setup', 'Image_logotipo', 'picture', fileLogo)
	endif

	if Empty(GetProperty('setup', 'Image_logotipo', 'picture')) .or. (RegistryRead(REGISTRY_PATH + "logotipo\uploaded") == 0)
		SetProperty('setup', 'Button_Delete_Logotipo', 'Enabled', false)
	else
		SetProperty('setup', 'Button_Delete_Logotipo', 'Enabled', true)
	endif

	SetProperty('setup', 'Button_Submit_Logotipo', 'Enabled', !Empty(GetProperty('setup', 'Image_logotipo', 'picture')))

return

procedure setup_Button_Submit_Certificado_action()
	local index := GetProperty("setup", "Grid_Empresas", "value")
	local cnpj := GetProperty('setup', 'Text_CNPJ', 'value')
	local filePFX := GetProperty('setup', 'Text_ArquivoPFX', 'value')
	local paswPFX := GetProperty('setup', 'Text_SenhaPFX', 'value')
	local paswUser := GetProperty('setup', 'Text_password', 'Value')
	local certificado, cdEncode64, fileLoaded, tudoCerto, expires_in
	local jsonResponse, periodoValidade, msgRetorno

	SetProperty('setup', 'Label_StatusPFX', 'value', '')

	if Empty(filePFX)
		MsgExclamation("Arquivo PFX não podem estar vazios!", "DFeMonitor " + appData:version + ": Arquivo PFX (Certificado A1)")
	elseif  Empty(paswPFX)
		MsgExclamation("Senha do certificado A1 inválida!", "DFeMonitor " + appData:version + ": Senha (Certificado A1)")
	elseif !hb_FileExists(filePFX)
		MsgExclamation("Arquivo " + filePFX + hb_eol() + "não encontrado!", "DFeMonitor " + appData:version + ": Arquivo PFX (Certificado A1)")
	elseif !(paswUser == cbxUsers:getCargo())
		MsgExclamation("Senha Inválida para o usuário " + cbxUsers:getDisplay() + "!" + hb_eol() + "Verifique na primeira guia (Configurações) se você digitou a senha correta do usuário selecionado.", "DFeMonitor " + appData:version + ": Senha")
	elseif Empty(cnpj)
		MsgExclamation("Selecione a empresa na grade da guia Configurações!", "DFeMonitor " + appData:version + ": Selecione uma Empresa")
	else
		// Submeter a Nuvem Fiscal e obter resposta
		SetProperty('setup', 'Label_StatusPFX', 'FontColor', YELLOW_OCRE)
		SetProperty('setup', 'Label_StatusPFX', 'value', 'Carregando...')
		SetProperty('setup', 'Label_StatusPFX', 'visible', true)
		SetProperty("setup", "ProgressBar_Transmitindo", "visible", true)
		SetProperty("setup", "ProgressBar_Transmitindo", "enabled", true)
		SET PROGRESSBAR ProgressBar_Transmitindo OF setup ENABLE MARQUEE UPDATED 10

		// Transmitir para a nuvem fiscal e pegar retorno
		fileLoaded := hb_MemoRead(filePFX)
		cdEncode64 := HB_Base64Encode(fileLoaded)
		certificado := TApiCertificado():new(appEmpresas:empresas[index])
		tudoCerto := certificado:Cadastrar(cdEncode64, paswPFX)

		if tudoCerto

			jsonResponse := hb_jsonDecode(certificado:response)
			SetProperty('setup', 'Text_RazaoSocial', 'value', jsonResponse['nome_razao_social'])
			SetProperty('setup', 'Text_CNPJ_logotipo', 'value', jsonResponse['cpf_cnpj'])
			SetProperty('setup', 'Text_Assunto', 'value', jsonResponse['subject_name'])
			SetProperty('setup', 'Text_Emissor', 'value', jsonResponse['issuer_name'])
			SetProperty('setup', 'Text_Serie', 'value', jsonResponse['serial_number'])

			// 2019-08-24T14:15:22Z => 2019-08-24 14:15:22
			expires_in := Left(StrTran(jsonResponse['not_valid_after'], "T", " "), 19)
			periodoValidade := Left(StrTran(jsonResponse['not_valid_before'], "T", " "), 19)
			periodoValidade += " à " + expires_in
			SetProperty('setup', 'Text_Validade', 'value', periodoValidade)

			RegistryWrite(REGISTRY_PATH + "certificado\CertFile", filePFX)
			RegistryWrite(REGISTRY_PATH + "certificado\cnpj", jsonResponse['cpf_cnpj'])
			RegistryWrite(REGISTRY_PATH + "certificado\expires_in", expires_in)
			RegistryWrite(REGISTRY_PATH + "certificado\issuer_name", jsonResponse['issuer_name'])
			RegistryWrite(REGISTRY_PATH + "certificado\nome_razao_social", jsonResponse['nome_razao_social'])
			RegistryWrite(REGISTRY_PATH + "certificado\serial_number", jsonResponse['serial_number'])
			RegistryWrite(REGISTRY_PATH + "certificado\subject_name", jsonResponse['subject_name'])
			RegistryWrite(REGISTRY_PATH + "certificado\uploaded", 1)
			RegistryWrite(REGISTRY_PATH + "certificado\validity_period", periodoValidade)

		else

			// Response Schema
			if certificado:ContentType == "json"
				msgRetorno := {}
				jsonResponse := hb_jsonDecode(certificado:response)
				AAdd(msgRetorno, "codigo: " + jsonResponse['error']['code'])
				AAdd(msgRetorno, "Mensagem: " + jsonResponse['error']['message'])
			else
				msgRetorno := certificado:response
			endif
			saveLog(msgRetorno, "Error")

		endif

		SET PROGRESSBAR ProgressBar_Transmitindo OF setup DISABLE MARQUEE
		SetProperty("setup", "ProgressBar_Transmitindo", "enabled", false)
		SetProperty("setup", "ProgressBar_Transmitindo", "visible", false)

		if tudoCerto
			SetProperty('setup', 'Label_StatusPFX', 'value', 'Certificado carregado com sucesso!')
			SetProperty('setup', 'Label_StatusPFX', 'FontColor', GREEN_OCRE)
		else
			SetProperty('setup', 'Label_StatusPFX', 'value', 'Erro ao carregar Certificado!')
			SetProperty('setup', 'Label_StatusPFX', 'FontColor', RED)
			MsgStop(msgRetorno, "DFeMonitor " + appData:version + ": Erro ao carregar Certificado A1")
		endif

	endif

return

procedure setup_Button_Submit_Logotipo_action()
	MsgInfo("Módulo desativado!", "Envio do logotipo")

/*
	* Por motivos desconhecidos, o logotipo não é enviado corretamente, é provavel que o problema estaja na
	* configuração da DLL win_oleCreateObject("MSXML2.ServerXMLHTTP.6.0") para enviar arquivos do tipo image/jpeg,png,tif...

	local cnpj := GetProperty('setup', 'Text_CNPJ', 'value')
	local fileLogo := GetProperty('setup', 'Image_logotipo', 'picture')
	local paswUser := GetProperty('setup', 'Text_password', 'Value')
	local logotipo, nFileHandle, nSize
    local index := GetProperty("setup", "Grid_Empresas", "value")
	local empresa := appEmpresas:empresas[index]

	private binaryFile

	SetProperty('setup', 'Label_StatusLogotipo', 'value', '')

	if Empty(fileLogo)
		MsgExclamation("Arquivo Logotipo não pode estar vazio!", "DFeMonitor " + appData:version + ": Arquivo de Logotipo")
	elseif !hb_FileExists(fileLogo)
		MsgExclamation("Arquivo " + fileLogo + hb_eol() + "não encontrado!", "DFeMonitor " + appData:version + ": Arquivo de Logotipo")
	elseif !(paswUser == cbxUsers:getCargo())
		MsgExclamation("Senha Inválida para o usuário " + cbxUsers:getDisplay() + "!" + hb_eol() + ;
			"Verifique na primeira guia (Configurações) se você digitou a senha correta do usuário selecionado.", "DFeMonitor " + appData:version + ": Senha")
	elseif Empty(cnpj)
		MsgExclamation("Selecione a empresa na grade da guia Configurações!", "DFeMonitor " + appData:version + ": Selecione uma Empresa")
	else
		// Submeter a Nuvem Fiscal e obter resposta
		SetProperty('setup', 'Label_StatusLogotipo', 'value', 'Carregando...')
		SetProperty('setup', 'Label_StatusLogotipo', 'FontColor', YELLOW_OCRE)

		// Transmitir para a nuvem fiscal e pegar retorno

		nFileHandle := FOpen(fileLogo)

		if !(nFileHandle == F_ERROR)
			nSize := FSeek(nFileHandle, 0, 2)
			FSeek(nFileHandle, 0, 0)
			binaryFile := Space(nSize)
			nSize := FRead(nFileHandle, @binaryFile, nSize)
			FClose(nFileHandle)

			if !Empty(binaryFile)
				logotipo := TApiLogotipo():new(empresa)
				if logotipo:Enviar(binaryFile, hb_FNameExt(fileLogo))
					RegistryWrite(REGISTRY_PATH + "logotipo\LogoFile", fileLogo)
					RegistryWrite(REGISTRY_PATH + "logotipo\uploaded", 1)
					SetProperty('setup', 'Label_StatusLogotipo', 'value', 'Logotipo carregado com sucesso!')
					SetProperty('setup', 'Label_StatusLogotipo', 'FontColor', GREEN_OCRE)
				else
					SetProperty('setup', 'Label_StatusLogotipo', 'value', 'Erro ao carregar Logotipo!')
					SetProperty('setup', 'Label_StatusLogotipo', 'FontColor', RED)
					MsgStop(getMessageApiError(logotipo), "DFeMonitor " + appData:version + ": Erro ao carregar Logotipo")
				endif
			else
				MsgStop({"Erro ao ler o arquivo de imagem.", hb_eol(), "Erro: ", }, "DFeMonitor " + appData:version + ": Erro ao ler Logotipo")
			endif
		else
			MsgStop({"Erro ao abrir o arquivo de imagem.", "Erro: ", FError()}, "DFeMonitor " + appData:version + ": Erro ao carregar Logotipo")
		endif

	endif

	if Empty(GetProperty('setup', 'Image_logotipo', 'picture')) .or. (RegistryRead(REGISTRY_PATH + "logotipo\uploaded") == 0)
		SetProperty('setup', 'Button_Delete_Logotipo', 'Enabled', false)
	else
		SetProperty('setup', 'Button_Delete_Logotipo', 'Enabled', true)
	endif

	SetProperty('setup', 'Button_Submit_Logotipo', 'Enabled', !Empty(GetProperty('setup', 'Image_logotipo', 'picture')))
*/
return

procedure setup_button_delete_logotipo_action()
	local cnpj, logo
	local paswUser := GetProperty('setup', 'Text_password', 'Value')
	local index := GetProperty("setup", "Grid_Empresas", "value")

	if !(paswUser == cbxUsers:getCargo())
		MsgExclamation("Senha Inválida para o usuário " + cbxUsers:getDisplay() + "!" + hb_eol() + ;
			"Verifique na primeira guia (Configurações) se você digitou a senha correta do usuário selecionado.", "DFeMonitor " + appData:version + ": Senha")
	elseif MsgYesNo("Confirme a remoção do logotipo no PDF da DACTE/DAMDFE", "Remover Logotipo", false)
		SetProperty('setup', 'Label_StatusLogotipo', 'value', 'Deletando Logo...')
		SetProperty('setup', 'Label_StatusLogotipo', 'FontColor', YELLOW_OCRE)
		cnpj := GetProperty('setup', 'Text_CNPJ', 'value')
		logo := TApiLogotipo():new(appEmpresas:empresas[index])
		if logo:Deletar()
			SetProperty('setup', 'Image_logotipo', 'picture', NIL)
			SetProperty('setup', 'Label_StatusLogotipo', 'value', 'Logotipo Removido com Sucesso!')
			SetProperty('setup', 'Label_StatusLogotipo', 'FontColor', GREEN_OCRE)
			RegistryWrite(REGISTRY_PATH + "logotipo\LogoFile", "")
			RegistryWrite(REGISTRY_PATH + "logotipo\uploaded", 0)
			saveLog("Usuário " + cbxUsers:getDisplay() + " deletou o logotipo!")
		else
			SetProperty('setup', 'Label_StatusLogotipo', 'value', 'Erro ao Remover Logotipo!')
			SetProperty('setup', 'Label_StatusLogotipo', 'FontColor', RED)
			MsgStop(getMessageApiError(logo), "DFeMonitor " + appData:version + ": Erro ao remover Logo do PDF da DACTE/DAMDFE")
		endif
	endif

	if Empty(GetProperty('setup', 'Image_logotipo', 'picture')) .or. (RegistryRead(REGISTRY_PATH + "logotipo\uploaded") == 0)
		SetProperty('setup', 'Button_Delete_Logotipo', 'Enabled', false)
	else
		SetProperty('setup', 'Button_Delete_Logotipo', 'Enabled', true)
	endif

	SetProperty('setup', 'Button_Submit_Logotipo', 'Enabled', !Empty(GetProperty('setup', 'Image_logotipo', 'picture')))

return

procedure msgDebugInfo(inMsg)
	local outMsg := {'Chamado de: ', ProcName(1) + '(' + hb_NToS(ProcLine(1)) + ') -->', hb_eol()}
	local msg
	if (ValType(inMsg) == 'A')
		for each msg in inMsg
			AAdd(outMsg, msg)
		next
	else
		AAdd(outMsg, inMsg)
	endif
	MsgInfo(outMsg, 'DEBUG INFO')
return

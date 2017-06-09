--[[ termostatoAA
	Dispositivo virtual
	modeButton.lua
	por Manuel Pascual
------------------------------------------------------------------------------]]

--[[----- CONFIGURACION DE USUARIO -------------------------------------------]]
--[[----- FIN CONFIGURACION DE USUARIO ---------------------------------------]]

--[[----- NO CAMBIAR EL CODIGO A PARTIR DE AQUI ------------------------------]]

--[[----- CONFIGURACION AVANZADA ---------------------------------------------]]
local _selfId = fibaro:getSelfId()  -- ID de este dispositivo virtual
--[[----- FIN CONFIGURACION AVANZADA -----------------------------------------]]

function getSetAA(option, functionName, argument)
  if argument then argument = ','..argument else argument = '' end
  local command = option..',1:'..functionName..argument..'\r\n'
  local ip = fibaro:getValue(_selfId, 'IPAddress')
  local port = fibaro:getValue(_selfId, 'TCPPort')
  tcpSocket = Net.FTcpSocket(ip, port)
  tcpSocket:setReadTimeout(1000)
  result, errCode = tcpSocket:write(command)
  statusLabel, statusErr = tcpSocket:read()
  tcpSocket:disconnect()
  if errCode == 0 then
    return statusLabel, statusErr
  end
  return 'Err', errCode
end

-- obtener modo
statusLabel, statusErr = getSetAA('GET', 'MODE')
fibaro:debug(statusErr..': '..statusLabel)
local p2 = string.find(statusLabel, 'MODE,')
local modeLabel = string.sub(statusLabel, p2 + 5, #statusLabel - 2)

-- si no hay error
if statusErr == 0 then
	local modesText = {mode}
	modesText[1] = 'COOL'; modesText[2] = 'DRY'; modesText[3] = 'HEAT'
	modesText[4] = 'FAN'; modesText[5] = 'AUTO'
	local modesNum = {num}
	modesNum['COOL'] = 1; modesNum['DRY'] = 2; modesNum['HEAT'] = 3
	modesNum['FAN'] = 4; modesNum['AUTO'] = 5
	local modesIcon = {icon}
	modesIcon[1] = '❄️'; modesIcon[2] = '💧'; modesIcon[3] = '☀️';
	modesIcon[4] = '♻️'; modesIcon[5] = 'A'
	local modeNum = modesNum[modeLabel]
	local modeText = modesText[modeNum]
	local modeIcon = modesIcon[modeNum]

	-- cambiar al siguiente modo
	fibaro:debug('Cambiando...')
	if modeNum + 1 > #modesText then
		getSetAA('SET', 'MODE', modesText[1])
	else
		getSetAA('SET', 'MODE', modesText[modeNum + 1])
	end

	-- esperar a que se aplique la acción
  fibaro:sleep(1500)

	-- obtener modo después de aplicar acción
	statusLabel, statusErr = getSetAA('GET', 'MODE')
  fibaro:debug(statusErr..': '..statusLabel)
  local p2 = string.find(statusLabel, 'MODE,')
  local newModeText = string.sub(statusLabel, p2 + 5, #statusLabel - 2)
	local newModeNum = modesNum[newModeText]
	local newModeIcon = modesIcon[newModeNum]

	-- obtener etiqueta actual
  local modeLabel = fibaro:get(_selfId, "ui.modeLabel.value")

	-- actualizar etiqueta de estado modo y velocidad ventilador
  --Status:OFF Mode:AUTO Fan:AUTO
  modeLabel = string.gsub(modeLabel, 'Mode:'..modeIcon, 'Mode:'..newModeIcon)
  fibaro:debug(modeLabel)
  fibaro:call(_selfId, "setProperty", "ui.modeLabel.value", modeLabel)
else
	fibaro:debug('Error: '..errCode..' '..statusErr)
end

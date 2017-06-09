--[[ termostatoAA
	Dispositivo virtual
	oNOFFButton.lua
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
  local statusLabel, statusErr = tcpSocket:read()
  tcpSocket:disconnect()
  if errCode == 0 then
    return statusLabel, statusErr
  end
  return 'Err', errCode
end

-- recuperar el estado actual
local statusLabel, statusErr = getSetAA('GET', 'ONOFF')

-- si no hay error
if statusErr == 0 then
  -- Comprobar el estado CHN,1:ONOFF,OFF
  local p2 = string.find(statusLabel, 'ONOFF,')
  statusLabel = string.sub(statusLabel, p2 + 6 , #statusLabel - 2)
  -- mostrar estado antes de acción
  -- si está encendifo ON
  if statusLabel == 'ON' then
    -- apagar
    fibaro:debug('Apagando...')
    getSetAA('SET', 'ONOFF', 'OFF')
  else
    -- encender
    fibaro:debug('Encendiendo...')
    getSetAA('SET', 'ONOFF', 'ON')
  end
  -- esperar acción
  fibaro:sleep(1500)

  -- obtener estado despues de accion
  newStatusLabel, statusErr = getSetAA('GET', 'ONOFF')
  fibaro:debug(statusErr..': '..newStatusLabel)
  local p2 = string.find(newStatusLabel, 'ONOFF,')
  local newStatusLabel = string.sub(newStatusLabel, p2 + 6, #newStatusLabel -2 )
  fibaro:debug(newStatusLabel)

  -- obtener etiqueta actual
  local thisLabel = fibaro:get(_selfId, "ui.modeLabel.value")

  -- actualizar etiqueta de estado modo y velocidad ventilador
  --Status:OFF Mode:AUTO Fan:AUTO
  fibaro:debug('statusLabel: '..statusLabel..' newStatusLabel:'..newStatusLabel)
  thisLabel = string.gsub(thisLabel, 'Status:'..statusLabel,
   'Status:'..newStatusLabel)
  fibaro:debug(thisLabel)
  fibaro:call(_selfId, "setProperty", "ui.modeLabel.value", thisLabel)

else
  fibaro:debug('Error: '..errCode..' '..statusErr)
end

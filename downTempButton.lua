--[[ termostatoAA
	Dispositivo virtual
	downTempButton.lua
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

-- obtener temperatura consigna
statusLabel, statusErr = getSetAA('GET', 'SETPTEMP')
fibaro:debug(statusErr..': '..statusLabel)
local p2 = string.find(statusLabel, 'SETPTEMP,')
local setpTemp = tonumber(string.sub(statusLabel, p2 + 9 ))

-- si no hay error
if statusErr == 0 then
  -- Comprobar temperatura mínima
  local minTemp = 18 * 10
  if setpTemp > minTemp then
    -- bajar temperatura de consigna
    fibaro:debug('Bajando...')
    getSetAA('SET', 'SETPTEMP', setpTemp - 10)
  else
    -- informar
    fibaro:debug('Temperatura mínima')
  end

  -- esperar acción
  fibaro:sleep(1500)

  -- formato a la temperatura origen
  setpTemp = string.format('%.1f', setpTemp / 10)..'ºC'

  -- obtener estado despues de accion
  statusLabel, statusErr = getSetAA('GET', 'SETPTEMP')
  local p2 = string.find(statusLabel, 'SETPTEMP,')
  local newSetpTemp = tonumber(string.sub(statusLabel, p2 + 9 ))

  -- formato temperatura destino
  newSetpTemp = string.format('%.1f', newSetpTemp / 10)..'ºC'

  -- obtener etiqueta actual
  local tempLabel = fibaro:get(_selfId, "ui.tempLabel.value")

  -- actualizar etiqueta de temperatura
  -- 31.0ºC / 25.0ºC
  tempLabel = string.gsub(tempLabel,
   '/ '..setpTemp, '/ '..newSetpTemp)
  fibaro:debug(tempLabel)
  fibaro:call(_selfId, "setProperty", "ui.tempLabel.value", tempLabel)
else
  fibaro:debug('Error: '..errCode..' '..statusErr)
end

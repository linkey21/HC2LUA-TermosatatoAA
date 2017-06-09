--[[ termostatoAA
	Dispositivo virtual
	downFanButton.lua
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

-- obtener velocidad ventilador
statusLabel, statusErr = getSetAA('GET', 'FANSP')
fibaro:debug(statusErr..': '..statusLabel)
local p2 = string.find(statusLabel, 'FANSP,')
local fanspLabel = string.sub(statusLabel, p2 + 6, #statusLabel - 2)
-- ajustar la etiqueta a un número
local fanSpeed
if fanspLabel == 'AUTO' then
  fanSpeed = 5
else
  fanSpeed = tonumber(fanspLabel)
end

-- si no hay error
if statusErr == 0 then
  -- Comprobar velocidad mínima 1, 2, 3, 4, AUTO = 5
  local minSpeed = 1
  -- ajustar ventilador
  if fanSpeed > minSpeed then
    getSetAA('SET', 'FANSP', fanSpeed - 1)
  else
    getSetAA('SET', 'FANSP', 'AUTO')
  end

  -- volver a poner AUTO si el valor es 5
  if fanSpeed == 5 then fanSpeed = 'AUTO' end

  -- esperar acción
  fibaro:sleep(1500)

  -- obtener estado despues de accion
  statusLabel, statusErr = getSetAA('GET', 'FANSP')
  fibaro:debug(statusErr..': '..statusLabel)
  local p2 = string.find(statusLabel, 'FANSP,')
  local fanspLabel = string.sub(statusLabel, p2 + 6, #statusLabel -2)
  if fanspLabel == 'AUTO' then fanspLabel = 'A' end

  -- obtener etiqueta actual
  local modeLabel = fibaro:get(_selfId, "ui.modeLabel.value")

  -- actualizar etiqueta de estado modo y velocidad ventilador
  --Status:OFF Mode:AUTO Fan:AUTO
  modeLabel = string.gsub(modeLabel, 'Fan:'..fanSpeed, 'Fan:'..fanspLabel)
  fibaro:debug(modeLabel)
  fibaro:call(_selfId, "setProperty", "ui.modeLabel.value", modeLabel)
else
  fibaro:debug('Error: '..errCode..' '..statusErr)
end

--[[ termostatoAA
	Dispositivo virtual
	mainLoop.lua
	por Manuel Pascual
------------------------------------------------------------------------------]]

--[[----- CONFIGURACION DE USUARIO -------------------------------------------]]
local iconON = 24
local iconOFF = 23
--[[----- FIN CONFIGURACION DE USUARIO ---------------------------------------]]

--[[----- NO CAMBIAR EL CODIGO A PARTIR DE AQUI ------------------------------]]

--[[----- CONFIGURACION AVANZADA ---------------------------------------------]]
local _selfId = fibaro:getSelfId()  -- ID de este dispositivo virtual
--[[----- FIN CONFIGURACION AVANZADA -----------------------------------------]]

--[[
ONOFF		ON		OFF
MODE		AUTO	HEAT	DRY		FAN		COOL
SETPTEMP	x10
FANSP		1		2		3		4
--]]
function getSetAA(option, functionName, argument)
  if argument then argument = ','..argument else argument = '' end
  local command = option..',1:'..functionName..argument..'\r\n'
  local ip = fibaro:getValue(_selfId, 'IPAddress')
  local port = fibaro:getValue(_selfId, 'TCPPort')
  -- esperar para no colisionar con otra solicitud
  fibaro:sleep(1000)
  tcpSocket = Net.FTcpSocket(ip, port)
  tcpSocket:setReadTimeout(1000)
  result, errCode = tcpSocket:write(command)
  if errCode == 0 then
    statusLabel, statusErr = tcpSocket:read()
    if statusErr == 0 then
      tcpSocket:disconnect()
      return statusLabel, statusErr
    end
    tcpSocket:disconnect()
    return 'Err', statusErr
  end
  tcpSocket:disconnect()
  return 'Err', errCode
end

-- actualizar id de dispositivo
fibaro:call(_selfId, "setProperty", "ui.idLabel.value", 'id: '.._selfId)

while true do
  -- obtener estado
  statusLabel, statusErr = getSetAA('GET', 'ONOFF')
  local onOffLabel
  if statusLabel and statusErr == 0 then -- si ha ido bien se refresca el valor
    local p2 = string.find(statusLabel, 'ONOFF,')
    onOffLabel = string.sub(statusLabel, p2 + 6,  #statusLabel - 2)
  else -- sino hay error se usa el valor de la etiqueta
    -- obtener etiqueta actual
    local modeLabel = fibaro:get(_selfId, "ui.modeLabel.value")
    local p1 = string.find(modeLabel, 'Status:')
    local p2 = string.find(modeLabel, 'Mode:')
    onOffLabel = string.sub(modeLabel, p1 + 7, p2 - 2)
  end
  fibaro:debug(onOffLabel)

  -- obtener velocidad ventilador
  statusLabel, statusErr = getSetAA('GET', 'FANSP')
  local fanspLabel
  if statusLabel and statusErr == 0 then -- si ha ido bien se refresca el valor
    local p2 = string.find(statusLabel, 'FANSP,')
    fanspLabel = string.sub(statusLabel, p2 + 6, #statusLabel - 2)
  else -- sino hay error se usa el valor de la etiqueta
    -- obtener etiqueta actual
    local modeLabel = fibaro:get(_selfId, "ui.modeLabel.value")
    local p1 = string.find(modeLabel, 'Fan:')
    fanspLabel = string.sub(modeLabel, p1 + 4)
  end
  if fanspLabel == 'AUTO' then fanspLabel = 'A' end
  fibaro:debug(fanspLabel)

  -- obtener modo
  statusLabel, statusErr = getSetAA('GET', 'MODE')
  local modeIcon
  if statusLabel and statusErr == 0 then -- si ha ido bien se refresca el valor
    local p2 = string.find(statusLabel, 'MODE,')
    local modeLabel = string.sub(statusLabel, p2 + 5, #statusLabel - 2)
    if modeLabel == 'COOL' then modeIcon = '❄️'
    elseif modeLabel == 'DRY' then modeIcon = '💧'
    elseif modeLabel == 'HEAT' then modeIcon = '☀️'
    elseif modeLabel == 'FAN' then modeIcon = '♻️'
    else modeIcon = 'A'
    end
  else -- sino hay error se usa el valor de la etiqueta
    -- obtener etiqueta actual
    local modeLabel = fibaro:get(_selfId, "ui.modeLabel.value")
    local p1 = string.find(modeLabel, 'Mode:')
    local p2 = string.find(modeLabel, 'Fan:')
    modeIcon = string.sub(modeLabel, p1 + 5, p2 - 2)
  end
  fibaro:debug(modeIcon)

  -- obtener temperatura ambiente
  statusLabel, statusErr = getSetAA('GET', 'AMBTEMP')
  local ambtempLabel
  if statusLabel and statusErr == 0 then -- si ha ido bien se refresca el valor
    local p2 = string.find(statusLabel, 'AMBTEMP,')
    ambtempLabel = tonumber(string.sub(statusLabel, p2 + 8 )) / 10
    ambtempLabel = string.format('%.1f', ambtempLabel)..'ºC'
  else -- sino hay error se usa el valor de la etiqueta
    -- obtener etiqueta actual
    local tempLabel = fibaro:get(_selfId, "ui.tempLabel.value")
    local p1 = string.find(tempLabel, '/')
    ambtempLabel = string.sub(tempLabel, 1, p1 - 2)
  end
  fibaro:debug(ambtempLabel)

  -- obtener temperatura consigna
  statusLabel, statusErr = getSetAA('GET', 'SETPTEMP')
  local setptempLabel
  if statusLabel and statusErr == 0 then -- si ha ido bien se refresca el valor
    local p2 = string.find(statusLabel, 'SETPTEMP,')
    setptempLabel = tonumber(string.sub(statusLabel, p2 + 9 )) / 10
    setptempLabel = string.format('%.1f', setptempLabel)..'ºC'
  else -- sino hay error se usa el valor de la etiqueta
    -- obtener etiqueta actual
    local tempLabel = fibaro:get(_selfId, "ui.tempLabel.value")
    local p1 = string.find(tempLabel, '/')
    setptempLabel = string.sub(tempLabel, p1 + 2)
  end
  fibaro:debug(setptempLabel)

  -- actualizar etiqueta de estado modo y velocidad ventilador
  fibaro:call(_selfId, "setProperty", "ui.modeLabel.value",
  'Status:'..onOffLabel..' Mode:'..modeIcon..' Fan:'..fanspLabel)

  -- actualizar etiqueta de temperatura
  fibaro:call(_selfId, "setProperty", "ui.tempLabel.value",
   ambtempLabel..' / '..setptempLabel)

  -- actualizar log
  fibaro:log(ambtempLabel..' / '..modeIcon..' / '..onOffLabel)

  -- actualizar iconON
  local currentIcon = iconOFF
  if onOffLabel == 'ON' then currentIcon = iconON end
  fibaro:call(_selfId, 'setProperty', "currentIcon", currentIcon)

  -- watchDog
  fibaro:debug('termostatoAA OK')

  -- actualizar cada...
  fibaro:sleep(10 * 1000)

  -- resetear  log
  fibaro:log('')

end

-- ❄️💧☀️♻️

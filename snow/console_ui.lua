require 'snow/snow'
require 'snow/console'


conui = {
  alpha = 0,
  command = '',
  history = { pointer = 1 },
  backgroundVertices = {
    0, 0,
    1, 0,   -- change 3 and 5 when drawing
    1, 300,
    0, 300
  }
}


function conui.load()
  snow:addEventListener(conui.eventListener, 0)
  snow:addSystem(conui.updateConsole, 2^30)
  snow:addRenderer(conui.drawConsole, 2^30)
  conui.font = love.graphics.newFont()
  conui.font:setLineHeight(1.2)
  conui.lineHeight = conui.font:getHeight()
end


function conui.eventListener(name, key, unicode)
  local open = cl_consoleVisible:get()

  if name == "keypressed" and key == "`" then
    if open > 0 then
      love.keyboard.setKeyRepeat(0, 0)
      open = 0
    else
      love.keyboard.setKeyRepeat(0.3, 0.1)
      open = 1
    end
    cl_consoleVisible:set(open)
    return true
  end

  if open > 0 and name == "keypressed" then
    local history = conui.history
    if #key == 1 and unicode then
      conui.command = conui.command .. string.char(unicode)
    elseif key == "backspace" and #conui.command > 0 then
      conui.command = conui.command:sub(1, -2)
    elseif key == "return" and #conui.command > 0 then
      local args = conui.command:arguments()
      console.call(false, unpack(args))
      table.insert(conui.history, conui.command)
      conui.history.pointer = #conui.history + 1
      conui.command = ''
    elseif key == "up" and history.pointer > 1 then
      history.pointer = history.pointer - 1
      conui.command = history[history.pointer]
    elseif key == "down" then
      local len = #history
      if history.pointer < len + 1 then
        history.pointer = history.pointer + 1
        if history.pointer <= len then
          conui.command = history[history.pointer]
        else
          conui.command = ''
        end
      end
    end
    return true
  elseif open and name == "keyreleased" then
    return true
  end

  return false
end


function conui.updateConsole(elapsed)
  local open = cl_consoleVisible:get()
  if open > 0 then
    if conui.alpha < 1 then
      conui.alpha = conui.alpha + 0.05
    elseif conui.alpha > 1 then
      conui.alpha = 1
    end
  else
    if conui.alpha > 0 then
      conui.alpha = conui.alpha - 0.05
    elseif conui.alpha < 0 then
      conui.alpha = 0
    end
  end
end


function conui.drawConsole()
  if conui.alpha == 0 then
    return
  end

  -- update background vertices
  local width = love.graphics.getWidth()
  conui.backgroundVertices[3] = width
  conui.backgroundVertices[5] = width

  love.graphics.push()
  love.graphics.setColor(80, 80, 80, conui.alpha * 255)
  love.graphics.translate(0, -300 * (1 - conui.alpha))
  love.graphics.polygon('fill', conui.backgroundVertices)

  love.graphics.setFont(conui.font)
  love.graphics.setColor(255, 255, 255, conui.alpha * 255)

  local lineHeight = conui.lineHeight
  local yoff = 296 - lineHeight
  if #conui.command > 0 then
    love.graphics.print(conui.command, 4, yoff)
  end
  yoff = yoff - lineHeight * 1.5

  for messageIndex = #snow._logMessages, 1, -1 do
    love.graphics.print(snow._logMessages[messageIndex], 4, yoff)
    yoff = yoff - conui.lineHeight
  end

  love.graphics.pop()
end


function conui.setFont(font)
  conui.font = font
end


conui.load()

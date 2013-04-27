require 'snow/snow'
require 'snow/console'
require 'snow/cvars'
require 'snow/console_ui'


function love.load(argv)
  local plus_byte = ("+"):byte()
  local numArgs = #argv

  for argindex = 2, numArgs do
    local param = argv[argindex]
    if param:byte(1) == plus_byte then
      local name = param:sub(2)
      argindex = argindex + 1
      if argindex > numArgs then break end
      console.call(true, name, argv[argindex])
    end
  end

  local gameScriptPath = fs_game:get() .. '/game.lua'
  if love.filesystem.isFile(gameScriptPath) then
    console.call("load", gameScriptPath)
  end
end


function love.run()
  snow:setTargetFPS(60)

  if not game then game = {} end

  if love.load then love.load(arg) end

  if not game then
    print "Game table erased post-load, terminating"
    return
  end

  local baseTime = love.timer.getTime()
  local simTime = 0

  if game.load then game.load() end

  while cl_shouldQuit:get() < 1 do

    local updateScreen = false
    local frameHertz = snow.frameHertz
    local currentTime = love.timer.getTime() - baseTime

    while simTime <= currentTime do
      updateScreen = true

      love.event.pump()
      for event, w, x, y, z in love.event.poll() do
        if not game.event or not game.event(event, w, x, y, z) then
          snow:dispatchEvent(event, w, x, y, z)
        end
      end
      love.event.clear()

      love.update(frameHertz)

      simTime = simTime + frameHertz
    end

    if updateScreen then
      love.draw()
      love.timer.sleep(r_frameSleep:get() or 0.001)
    end

  end

  if game.quit then game.quit() end
  if love.quit then love.quit() end
end


function love.update(elapsed)
  snow:doFrame(elapsed)
  console.updateCvars()
end


function love.draw()
  love.graphics.clear()
  if game and game.drawFrame then game.drawFrame() end
  snow:drawFrame()
  love.graphics.present()
end

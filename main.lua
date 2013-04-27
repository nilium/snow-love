require 'snow/snow'
require 'snow/console'
require 'snow/cvars'
require 'snow/console_ui'


function love.load(argv)
end


function love.run()
  snow:setTargetFPS(60)

  if love.load then love.load(arg) end

  local baseTime = love.timer.getTime()
  local simTime = 0

  print(snow.frameHertz)
  print(snow.targetFPS)

  while cl_shouldQuit:get() < 1 do

    love.event.pump()

    local updateScreen = false
    local frameHertz = snow.frameHertz
    local currentTime = love.timer.getTime() - baseTime

    while simTime <= currentTime do
      updateScreen = true

      love.event.pump()
      for event, w, x, y, z in love.event.poll() do
        snow:dispatchEvent(event, w, x, y, z)
      end
      love.event.clear()

      love.update(frameHertz)
      console.updateCvars()
      simTime = simTime + frameHertz
    end

    if updateScreen then
      love.draw()
      love.timer.sleep(r_frameSleep:get() or 0.001)
    end

  end

  if love.quit then love.quit() end
end


function love.update(elapsed)
  snow:doFrame(elapsed)
end


function love.draw()
  love.graphics.clear()
  snow:drawFrame()
  love.graphics.present()
end

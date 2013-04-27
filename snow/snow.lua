require 'snow/util'

snow = {
  _comparePrioritized = function(left, right)
    return left.priority < right.priority
  end,
  -- index -> { listener -> fn, priority -> num }
  _eventListeners = {
    needsSorting = false,
    {
      fn = function(name, ...)
        if name == "quit" then
          cl_shouldQuit:set(1)
          return true
        end
        return false
      end,
      priority = -100
    }
  },
  _renderers = { needsSorting = false },
  _systems = { needsSorting = false },
  _logMessages = {}
}


local terminalPrint = print
print = function(...)
  terminalPrint(...)
  local logString = ''
  local inputs = {...}
  for index, value in ipairs(inputs) do
    if index == 1 then
      logString = tostring(value)
    else
      logString = logString .. ' ' .. tostring(value)
    end
  end
  snow:log(logString)
end


function snow:log(message)
  table.insert(self._logMessages, message)
end


function snow:setTargetFPS(fps)
  if fps < 0.01 then
    print("Attempt to set target FPS to less than 0.01, ignoring request")
    return
  end
  self.targetFPS = fps
  self.frameHertz = 1.0 / fps
  print("Setting target FPS to " .. fps .. ' (' .. self.frameHertz .. ')')
end


function snow:addEventListener(fn, priority)
  table.insert(self._eventListeners, { fn = fn, priority = priority })
  self._eventListeners.needsSorting = true
end


function snow:removeEventListener(fn)
  local remove_index = 0 -- if zero, nothing found
  for index, value in ipairs(self._eventListeners) do
    if value.fn == fn then
      index = remove_index
      break
    end
  end

  if remove_index > 0 then
    table.remove(self._eventListeners)
  end
end


function snow:addRenderer(fn, priority)
  table.insert(self._renderers, { fn = fn, priority = priority })
  self._renderers.needsSorting = true
end


function snow:removeRenderer(fn)
  local remove_index = 0 -- if zero, nothing found
  for index, value in ipairs(self._renderers) do
    if value.fn == fn then
      index = remove_index
      break
    end
  end

  if remove_index > 0 then
    table.remove(self._renderers)
  end
end


function snow:addSystem(fn, priority)
  table.insert(self._systems, { fn = fn, priority = priority })
  self._systems.needsSorting = true
end


function snow:removeSystem(fn)
  local remove_index = 0 -- if zero, nothing found
  for index, value in ipairs(self._systems) do
    if value.fn == fn then
      index = remove_index
      break
    end
  end

  if remove_index > 0 then
    table.remove(self._systems)
  end
end


function snow:dispatchEvent(name, w, x, y, z)
  if self._eventListeners.needsSorting then
    table.sort(self._eventListeners, self._comparePrioritized)
    self._eventListeners.needsSorting = false
  end

  for index, listener in ipairs(self._eventListeners) do
    if listener.fn(name, w, x, y, z) then
      return
    end
  end
end


function snow:doFrame(elapsed)
  if self._systems.needsSorting then
    table.sort(self._systems, self._comparePrioritized)
    self._systems.needsSorting = false
  end

  for index, system in ipairs(self._systems) do
    system.fn(elapsed)
  end
end


function snow:drawFrame()
  if self._renderers.needsSorting then
    table.sort(self._renderers, self._comparePrioritized)
    self._renderers.needsSorting = false
  end

  for index, renderer in ipairs(self._renderers) do
    renderer.fn()
  end
end

require 'snow/console'
require 'snow/util'

local function define(T)
  if type(T[2]) ~= "function" then
    local flags = {}
    for k,v in pairs(T) do
      if type(k) ~= "number" then
        flags[k] = v
      end
    end
    _G[T[1]] = console.getCvar(T[1], T[2], flags)
  else
    console.makeCommand(T[1], T[2])
  end
end

-- Console variables
define { "fs_game", "base", readonly = true, init_only = true, delayed = false }
define { "r_frameSleep", 0.001, delayed = false}
define { "r_drawWalls", 1 }
define { "r_origin", { 0, 0 }, readonly = true }
define { "r_shadows", 1 }
define { "cl_shouldQuit", 0, readonly = true }
define { "cl_consoleVisible", 0 }

-- Console commands
define { "quit", function() cl_shouldQuit:set(1) end }
define { "load", function(...)
  local paths = { ... }
  for index, path in ipairs(paths) do
    print("Loading script '" .. tostring(path) .. "'")
    local chunk = love.filesystem.load(path)
    local result, errorMsg
    result, errorMsg = pcall(chunk)
    if not result then
      print("Error:")
      for i, m in ipairs(errorMsg:lines()) do
        print(m)
      end
    end
  end
end }
define { "print", function(...) print(...) end }

define { "r_targetFPS", function(fps)
  if not fps then
    print("r_targetFPS", snow.targetFPS)
  else
    snow:setTargetFPS(consolify(fps))
  end
end }

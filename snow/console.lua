require 'snow/util'


local allowUserCVars = false


function defaultCvarFlags()
  local flags = {
    readonly = false,
    init_only = false,
    saved = false,
    cheat = false,
    client = false,
    server = false,
    user = false,
    delayed = true,
    events = false,
    -- internal state
    modified = false
  }

  return flags
end


(function()
  if console_loaded then return end
  console_loaded = true
  console = {
    _boundCvars = {},
    _needUpdates = {}
  }
  setmetatable(console._needUpdates, { __mode = "k" })
end)()
console._defaultFlags = defaultCvarFlags()


cvar_t = {}


function console.makeCommand(name, fn)
  local prev = console._boundCvars[name]
  if prev then
    print("Overwriting previous " .. prev.kind .. "with new command")
  end

  console._boundCvars[name] = { kind = 'command', cmd = fn }
end


function console.makeCvar(name, default, flags)
  local prev = console._boundCvars[name]
  if prev then
    print("Overwriting previous " .. prev.kind .. "with new cvar")
  end

  local newCvar = {
    name = name,
    _value = consolify(default),
    flags = {}
  }

  table.merge(newCvar, cvar_t)
  table.merge(newCvar.flags, console._defaultFlags)

  if flags then
    table.merge(newCvar.flags, flags)
  end

  console._boundCvars[name] = { kind = 'cvar', cvar = newCvar }

  return newCvar
end


function cvar_t:canModify() --> bool
  local flags = self.flags
  if flags.cheat then
    local cheatvar = console.getCvar("cheats")
    if not cheatvar or cheatvar.get() < 1 then
      print("Cannot write to " .. self.name .. ": cvar is read-only unless 'cheats' is true")
      return false
    end
  end

  if flags.init_only then
    print("Cannot write to " .. self.name .. ": cvar can only be set at initialization")
    return false
  end

  if flags.readonly then
    print("Cannot write to " .. self.name .. ": cvar is read-only")
    return false
  end
  return true
end


function cvar_t:set(value) --> bool
  return self:setForced(value, true)
end


function cvar_t:setForced(value, force) --> bool
  value = consolify(value)

  if not force and not self:canModify() then
    return false
  end

  if self.flags.modified and self.flags.delayed then
    print("Over-writing previously cached value for cvar " .. self.name)
  end

  if self.flags.delayed then
    self._cache = value
    console._needUpdates[self] = self
  else
    local oldValue = self._value
    self._value = value
    if self.flags.events then
      love.event.push("cvar changed", self._value, oldValue)
    end
  end

  self.flags.modified = true

  return true
end


function cvar_t:get()
  return self._value
end


function cvar_t:update()
  if self.flags.modified and self.flags.delayed then
    self.flags.modified = false
    local oldValue = self._value
    self._value = self._cache
    self._cache = nil
    if self.flags.events then
      love.event.push("cvar changed", self._value, oldValue)
    end
  end
  self.flags.modified = false
end


function cvar_t:revokeChanges()
  if self.flags.modified and self.flags.delayed then
    self.flags.modified = false
    self._cache = nil
  end
end


function console.getUpdatedCvars()
  return table.clone(console._needUpdates)
end


function console.updateCvars()
  for key, value in pairs(console._needUpdates) do
    if value then
      value:update()
    end
  end

  console._needUpdates = {}
end


function console.getCvar(name, defaultValue, defaultFlags)
  local result = console._boundCvars[name]
  if result and result.kind == 'cvar' then
    return result
  elseif not result and defaultValue then
    return console.makeCvar(name, defaultValue, defaultFlags)
  else
    return nil
  end
end


function console.call(force, name, ...)
  local args
  if type(force) == "string" then
    args = { name, ... }
    name = force
    force = false
  else
    args = { ... }
  end

  local value = args[1]
  local binding = console._boundCvars[name]

  if not binding and allowUserCVars then
    if value then
      local cvar = console.getCvar(name, value, console._defaultFlags)
      if cvar then
        print(name, tostring(cvar:get()))
      end
      return cvar
    else
      print("No such cvar or command named '" .. name .. "'")
    end
  elseif not binding and not allowUserCVars then
    if value ~= nil then
      print("No such cvar or command named '" .. name .. "' and cannot create user cvar")
    else
      print("No such cvar or command named '" .. name .. "'")
    end
  elseif binding.kind == 'command' then
    print(name, unpack(args))
    return binding.cmd(unpack(args))
  elseif binding.kind == 'cvar' then
    if value then
      if binding.cvar:setForced(value, force) then
        print(name, tostring(value))
      end
      return binding.cvar
    else
      value = binding.cvar:get()
      print(name, tostring(value))
      return value
    end
  end
  return nil
end

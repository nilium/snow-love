local baseToString = tostring
function tostring(V)
  local metatable = getmetatable(V)
  if metatable and metatable.__tostring then
    return metatable.__tostring(V)
  elseif type(V) == "table" then
    return table.tostring(V)
  else
    return baseToString(V)
  end
end


function table.clone(origin, deep, _copies)
  if type(origin) ~= "table" then
    return nil
  end

  if deep and not _copies then
    _copies = {}
  end

  result = {}
  if deep then
    for key, value in pairs(origin) do
      key_copy = key
      value_copy = value

      if type(key_copy) == "table" then
        key_copy = _copies[key] or table.clone(key_copy, true, _copies)
        if not key_copy then
          key_copy = table.clone(key_copy, true, _copies)
          _copies[key] = key_copy
        end
      end

      if type(value_copy) == "table" then
        value_copy = _copies[value]
        if not value_copy then
          value_copy = table.clone(value_copy, true, _copies)
          _copies[value_copy] = value_copy
        end
      end

      result[key_copy] = value_copy
    end
  else
    for key, value in pairs(origin) do
      result[key] = value
    end
  end

  return result
end


function table.merge(dest, origin)
  for key, value in pairs(origin) do
    dest[key] = value
  end

  return dest
end


function table.tostring(T)
  local outs = '{'
  for k, v in pairs(T) do
    if #outs == 1 then
      outs = outs .. ' ' .. tostring(k) .. ' = ' .. v
    else
      outs = outs .. ', ' .. tostring(k) .. ' = ' .. v
    end
  end
  return outs
end


do
  local newline_byte = string.byte("\n")

  function string.lines(str)
    local result = {}

    local first = 1
    local second = 1
    local last = #str

    if last == 0 then
      return results
    end

    for second = second, last do
      local byte = str:byte(second)
      if byte == newline_byte then
        table.insert(result, str:sub(first, second - 1))
        first = second + 1
      end
    end

    if first ~= second then
      table.insert(result, str:sub(first, last))
    end

    return result
  end
end


do
  local single_quote_byte, double_quote_byte, space_byte, slash_byte
  single_quote_byte, double_quote_byte, space_byte, slash_byte = string.byte("'\" \\", 1, 4)

  function string.arguments(argString)
    local results = {}
    local first = 1
    local second = 1
    local last = #argString

    if last == 0 then
      return results
    end

    while first <= last do
      local delim = 0
      for first = first, last do
        delim = argString:byte(first)
        if delim ~= space_byte then
          break
        end
      end

      if first == last then
        break
      end

      if delim == single_quote_byte or delim == double_quote_byte then
        first = first + 1
        second = first + 1
        local escape = false
        while second <= last do
          local termChar = argString:byte(second)
          if not escape and termChar == delim then
            break
          elseif termChar == slash_byte then
            escape = not escape
          else
            escape = false
          end
          second = second + 1
        end
        table.insert(results, argString:sub(first, second - 1))
      else
        second = first + 1

        while second <= last do
          local termChar = argString:byte(second)
          if termChar == space_byte then
            break
          end
          second = second + 1
        end
        table.insert(results, argString:sub(first, second - 1))
      end

      first = second + 1
    end

    if first <= last then
      table.insert(results, argString:sub(first, last))
    end

    return results
  end
end


function consolify(value)
  if value == nil then
    -- nop
  elseif type(value) == "boolean" then
    if value then return 1 else return 0 end
  elseif type(value) == "string" then
    if value == "true" then
      value = 1
    elseif value == "false" then
      value = 0
    else
      -- try number conversion
      local num = tonumber(value)
      if num then value = num end
    end
  end
  return value
end


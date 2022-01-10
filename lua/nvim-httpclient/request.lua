-- luacheck: globals Request

local NONE = 0
local RUNNING = 1
local MISSING_DATA = 2
local DONE = 3
local ERROR = 4

-- Meta class
Request = {
  url = nil,
  verb = nil,
  path = nil,
  data = nil,
  data_filename = nil,
  result = nil,
  headers = nil,
  extract = nil,
  skipSSL = false,
  response = nil,
  state = NONE
}

-- should these be set via getters?
function Request:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self

   -- Tables have to be initialised
   o.data = {}
   o.headers = {}
   o.extract = {}
   -- self.result = {}
   return o
end

-- TODO Add tests
-- can be used to format? maybe user differnet classes?
function Request:get_results()
  local result_lines = {}
  if self.result then
    local vals = vim.split(self.result, "\n")
    for _, d in pairs(vals) do
      if d ~= "" then
        table.insert(result_lines, d)
      end
    end
  end
  return result_lines
end

function Request:add_data(key, value)
  table.insert(self.data, string.format("%s=%s", key, value))
end

function Request:add_extract(key, value)
  self.extract[key] = value
end

function Request:get_extracted_values()
  local t = {}

  if #self.extract == 0 then
    return
  end

  local json = vim.fn.json_decode({self.result})

  local extract = function(path)
    local chunk = "return function() return json." .. path .. " end"
    local func, err = load(chunk, nil, "t", {json = json})
    if func then
      local ok, add = pcall(func)
      if ok then
        return add()
      else
        -- TODO better handling of this error
        print("Execution error:", add)
      end
    else
        -- TODO better handling of this error
      print("Compilation error:", err)
    end
    return nil
  end

  for k,v in pairs(self.extract) do
    local value = extract(v)
    t[k] = value
  end

  return t
end

function Request:add_header(key, value)
  self.headers[key] = value
end

function Request:get_title()
  local verb = 'GET'
  if self.verb then
    verb = self.verb
  end
  return verb .. " - " .. self.url
end

-- function Request:get_data(variables)
function Request:get_data()
  self.state = NONE
  -- TODO can remove coplete_data as tracked in state
  -- local complete_data = true

  local data_string = ''
  if self.data_filename then
    return self.data_filename
  elseif self.data then
    -- data is key/value pairs
    for _, v in pairs(self.data) do
      -- local key = var_sub(k)
      -- local value = var_sub(v)
      -- TODO rather than build string, do list and join with a charecter
      data_string = data_string .. string.format('%s&', v)
      -- if not complete_data then
      --   return complete_data, nil
      -- end
    end
    -- trim remaining &
    if data_string:match("&$") then
      data_string = data_string:sub(1, -2)
    end
  end
  return data_string
end

function Request:get_url()
  local url = self.url
  if self.path then
    if self.path:match('^/') then
      url = url .. self.path
    else
      url = url .. '/' .. self.path
    end
  end
  return url
end

-- TODO add test
function Request:set_running()
  self.state = RUNNING
end

-- TODO add test
function Request:is_running()
  return self.state == RUNNING
end

-- TODO add test
function Request:set_done()
  self.state = DONE
end

-- TODO add test
function Request:set_failed()
  self.state = ERROR
end

-- TODO add test
function Request:is_done()
  return self.state == DONE
end

-- TODO add test
function Request:is_queued()
  return self.state == NONE
end

function Request:is_missing_data()
  return self.state == MISSING_DATA
end

function Request:is_failed()
  return self.state == ERROR
end

local function substitute_variables(args, variables)
  local missing_data = false

  for index, arg in ipairs(args) do
    local subbed_string = arg
    for var in arg:gmatch("@([%w-_]+)@") do
      -- local var = arg:match("@([%w-_]+)@")
      if var then
        -- TODO only handles a single substitute
        local value = variables[var]
        if value then
          subbed_string = subbed_string:gsub("@" .. var .. "@", value)
        else
          -- TODO this just returns early... doesn't check for other missing/availabel vars, so not great
          missing_data = true
        end
      end
    end
    args[index] = subbed_string

  end
  return missing_data, args
end

-- TODO spawn takes arguments, so is it worth building this as string? probably not!
function Request:get_curl(variables, inspect)
  local args = {}

  local verb = 'GET'
  if self.verb then
    verb = self.verb
  end

  local data = self:get_data()

  table.insert(args, "-X")
  table.insert(args, verb)

  -- are there query parameters to add
  -- TODO rather than POST, check for GET or DELETE
  -- TODO no handling of PATCH
  -- TODO swap the logic here
  if data ~= '' then
    if verb == "POST" or verb == "PUT" then
      table.insert(args, self:get_url())
      table.insert(args, "--data")
      table.insert(args, data)
    else
      table.insert(args, string.format('%s?%s', self:get_url(), data))
    end
  else
    table.insert(args, self:get_url())
  end

  for k,v in pairs(self.headers) do
    table.insert(args, "-H")
    if inspect then
      table.insert(args, string.format("'%s: %s'", k, v))
    else
      table.insert(args, string.format("%s: %s", k, v))
    end
  end

  local missing_data, subbed_curl = substitute_variables(args, variables)
  if missing_data then
    self.state = MISSING_DATA
  end

  return subbed_curl
end

-- luacheck: globals Request
require'nvim-httpclient.request'

local M = {}

-- TODO change scope to be in parse func
local requests
local variables = {}

function M.reset()
  requests = {}
  variables = {}
end

function M.add_request(request)
  if request and request.url then
    table.insert(requests, request)
  end
end

local function is_url(s)
  if s:match('^http[s]?://') then
    return true
  elseif s:match('^www.') then
    return true
  elseif s:match('^[^@](.*)%.(.*)$') then
    return true
  end
  return false
end

function M.parse_lines(buf_lines)
  M.reset()
  local req = Request:new(nil)

-- TODO add json block support
-- TODO special json headers
  for _,l in pairs(buf_lines) do

    -- matches a comment
    if l:match('^%s*#') then
      goto skip_to_next_line
    -- matches if to use skip ssl flag
    elseif l:match('^skipSSL$') then
      req.skipSSL = true
      -- match variable
    elseif l:match("^V%s+(.*)[=:](.*)") or
    l:match("^VAR%s+(.*)[=:](.*)") then
      local key, value = l:match("[V][A][R]%s+(.*)[=:](.*)")
      variables[key] = value
    elseif l:match("^S%s+(.*)[=:](.*)") or
    l:match("^SET%s+(.*)[=:](.*)") then
      local key, value = l:match("^[sS][eE][tT]%s+(.*)[=:](.*)")
      req:add_extract(key, value)
      -- matches url
    elseif is_url(l) then
      req.url = l
      -- matches headers
    elseif l:match('^H[EADER]*%s+.*[=:]') or
      l:match('^HEADER*%s+.*[=:]') then
      local key,value = l:match('^H[EADER]*%s+(.*)[=:](.*)')
      req:add_header(key, vim.trim(value))
      -- matches verb and path
      -- TODO should path always start with /
    elseif l:match('^%a+%s.+') then
      local verb, path = l:match('(.*)%s(.*)')
      req.verb = verb
      req.path = path
      -- Matches data key value pairs
    elseif l:match('^(.*)[=:](.*)$') then
      local key,value = l:match('(.*)[=:](.*)')
      req:add_data(key, value)
      -- match file for data
    elseif l:match('^%@') then
      req.data_filename = l
    elseif l:match('^%s*$') then
      M.add_request(req)
      req = Request:new(nil)
    end
    ::skip_to_next_line::
  end
  M.add_request(req)

  return requests, variables
end

function M.get_requests() return requests end

return M

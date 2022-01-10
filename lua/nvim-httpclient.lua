local api = vim.api
local parser = require('nvim-httpclient.parser')
local runner = require('nvim-httpclient.runner')
local view = require('nvim-httpclient.view')
local draw = require('ui.window.draw')
local M = {}
local variables

local function error_message(message)
  api.nvim_command('echohl ErrorMsg')
    api.nvim_command('echom "' .. message .. '"')
  api.nvim_command('echohl None')
end

M.config = {
  -- highlight group to use for message
  progress_running_highlight = "WarningMsg",
  progress_complete_highlight = "WarningMsg",
  -- handlers used to update status and show results
  update_status = view.show_status,
  update_results = view.update_result_buf,
  -- register to use, when inspecting a HTTP block
  -- if nil then does nothing
  register = "+",
  -- enable/disabled keymaps
  enable_keymaps = true,
  -- Run file
  run_file = "<leader>gtf",
  -- run last command
  run_last = "<leader>gtt",
  -- run current http block
  run_current = "<leader>gtn",
  -- inspect current http block
  inspect_current = "<leader>gti",
}

function M.get_current()
  local linenr = api.nvim_win_get_cursor(0)[1]
  local lines = {}
  local cur = linenr

  local get_line = function(num)
    local line = api.nvim_buf_get_lines(0, num - 1, num, false)[1]
    if not line then return nil end
    if line:match("^%s*$") then return nil end
    return line
  end

  repeat
    local line = get_line(cur)
    if not line then break end
    table.insert(lines, 1, line)
    cur = cur - 1
  until(cur < 0)

  cur = linenr + 1
  repeat
    local line = get_line(cur)
    if not line then break end
    table.insert(lines, line)
    cur = cur + 1
  until(false)

  return lines
end

local function parse_file()
  local lines = api.nvim_buf_get_lines(0, 0, api.nvim_buf_line_count(0), false)
  local requests
  requests,variables = parser.parse_lines(lines)
  return requests
end

-- FIXME currently broken when inspecting request with missing data
-- FIXME check request with headers...
local function inspect_curl()
  local filetype = api.nvim_buf_get_option(0, 'filetype')

  if filetype ~= 'http' then
    error_message('Must be filetype: http')
    return
  end

  -- if variables nil then parse file to populate first
  if not variables then
    parse_file()
  end

  local lines = M.get_current()
  local requests,_ = parser.parse_lines(lines) -- luacheck: ignore

  if #requests > 0 then
    local curl = "curl " .. table.concat(requests[1]:get_curl(variables, true), " ")
    api.nvim_command("echo \"" .. curl .. "\"")
    if M.config.register then
      api.nvim_command(string.format('let @%s = "%s"', M.config.register, curl))
    end
  else
    error_message("No request found")
  end

end

local function run(current)
  current = current or false

  local filetype = api.nvim_buf_get_option(0, 'filetype')

  if filetype ~= 'http' then
    error_message('Must be filetype: http')
    return
  end

  local update_view = function(...)
    if  not M.config.update_results then return end

    M.config.update_results(...)
  end

  local update_status = function(...)
    if not M.config.update_status then return end

    M.config.update_status(M.config.progress_running_highlight, M.config.progress_complete_highlight, ...)
  end

  local requests
  if current then
    -- if variables nil then parse file to populate first
    if not variables then
      parse_file()
    end

    local lines = M.get_current()
    requests,_ = parser.parse_lines(lines) -- luacheck: ignore
  else
    requests = parse_file()
  end

  view.create_result_scratch_buf()
  draw.open_draw(view.result_buf)

  runner.make_requests(requests, variables, update_status, update_view)
end

local function run_current()
  run(true)
end

local function run_file()
  run(false)
end


function M.set_buf_keymaps()
  if  M.config.enable_keymaps then
    local opts = {noremap = true, silent = true}
    local function keymap(...) vim.api.nvim_buf_set_keymap(0, ...) end

    -- Run all http requests in file
    keymap("n", M.config.run_file, ":HttpclientRunFile<CR>", opts)
    -- TODO this is not yet implemented
    keymap("n", M.config.run_file, ":HttpclientRunFile<CR>", opts)
    keymap("n", M.config.run_current, ":HttpclientRunCurrent<CR>", opts)
    keymap("n", M.config.inspect_current, ":HttpclientInspectCurrent<CR>", opts)
  end
end

function M.setup(user_opts)
  M.config = vim.tbl_extend('force', M.config, user_opts or {})

  vim.api.nvim_add_user_command(
  "HttpclientRunFile",
  run_file,
  {force = true}
  )

  vim.api.nvim_add_user_command(
  'HttpclientOpenResults',
  open_results,
  {force = true}
  )

  vim.api.nvim_add_user_command(
  'HttpclientRunCurrent',
  run_current,
  {force = true}
  )

  vim.api.nvim_add_user_command(
  'HttpclientInspectCurrent',
  inspect_curl,
  {force = true}
  )

  vim.cmd([[augroup http_filetype_detect
  autocmd BufNewFile,BufRead *.http set filetype=http
  autocmd FileType http lua require(\"nvim-httpclient\").set_buf_keymaps()
  autocmd FileType http set commentstring=#\ %s
  autocmd!
  augroup END]])
end

return M

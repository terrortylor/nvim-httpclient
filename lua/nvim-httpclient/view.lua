local api = vim.api

local M = {}

function M.clear_result_buf(result_buf)
  api.nvim_buf_set_lines(
  result_buf,
  0,
  api.nvim_buf_line_count(result_buf),
  false,
  {}
  )
end

function M.add_lines(result_buf, lines)
  local buf_start = api.nvim_buf_line_count(result_buf)
  local buf_end = buf_start

  -- An empty buffer still had 1 line
  if buf_start == 1 then
    buf_start = 0
  end

  api.nvim_buf_set_lines(result_buf, buf_start, buf_end, false, lines)
end

function M.update_result_buf(result_buf, requests)
  -- TODO is this required is add_lines workes out lines to replace first?
  M.clear_result_buf(result_buf)

  for _,req in pairs(requests) do
    M.add_lines(result_buf, {
      '#######################',
      req:get_title()
    })
    -- TODO if json then format
    M.add_lines(result_buf, req:get_results())
    M.add_lines(result_buf, {
      '',
    })

  end
end

function M.show_status(hl_running, hl_complete, is_running, requests)
  local print_status = function(hl, msg)
    api.nvim_command("echohl " .. hl)
    api.nvim_command("echo '" .. msg .. "'")
    api.nvim_command("echohl None")
  end

  local status
  local hl
  local state

  if is_running then
    state = "Running"
    hl = hl_running
  else
    state = "Finished"
    hl = hl_complete
  end

  local total = #requests
  local running = 0
  local complete = 0
  local missing = 0
  local failed = 0

  for i = 1, #requests do
    if requests[i].is_done then complete = complete + 1
    elseif requests[i].is_running() then running = running + 1
    elseif requests[i].is_missing_data() then missing = missing + 1
    elseif requests[i].is_failed() then failed = failed + 1
    end
  end

  status =  string.format("%s: %s of %s complete", state, complete, total)

  if missing > 0 then
    status = status .. string.format(", %s missing data", missing)
  end

  if failed > 0 then
    status = status .. string.format(", %s failed", failed)
  end

  print_status(hl,status)
end

-- TODO rename to create_result_buf
function M.create_result_scratch_buf(result_buf)
  if result_buf then
    M.clear_result_buf(result_buf)
  else
    -- create unlisted scratch buffer
    result_buf = api.nvim_create_buf(false, true)

    -- TODO this leaves the window open though.. how to bind without coupling?
    local command = {
      "autocmd",
      "BufUnload",
      "<buffer=" .. result_buf .."> ++once",
      ":lua require('nvim-httpclient').result_buf = nil"
    }
    vim.cmd(table.concat(command, " "))

    api.nvim_buf_set_option(result_buf, "filetype", "httpresult")
    api.nvim_buf_set_name(result_buf, 'HttpClientResult')
    -- TODO set not modifiable
  end

  return result_buf
end

return M

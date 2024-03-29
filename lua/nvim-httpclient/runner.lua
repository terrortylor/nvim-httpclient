-- FIXME all howing as complete even when some missing
local M = {}

local requests
local count = 0
local variables

local running = false

local update_status_callback
local update_view_callback

function M.async_curl(request)
  local curl_args = request:get_curl(variables, false)
  -- nil if missing data
  if not curl_args then return end

  request:set_running()

  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)

  local callback = function(err, data)
    if err then
      -- TODO handle err
      request:add_result_line("ERROR")
      request:set_failed()
    end
    if data then request.result = data end
  end

  -- TODO move to func, request would benefit from being class
  local handle
  handle = vim.loop.spawn('curl', {
      args = curl_args,
      stdio = {stdout,stderr}
    },
    vim.schedule_wrap(function()
        stdout:read_stop()
        stderr:read_stop()
        stdout:close()
        stderr:close()
        handle:close()

        request:set_done()
        count = count + 1

        -- TODO breaks if error in response or not JSON
        -- local vars = request:get_extracted_values()
        -- if vars then
        --   for k,v in pairs(vars) do
        --     variables[k] = v
        --   end
        --   M.go()
        -- end

        -- -- FIXME this cleanup is not accurate, as is missing data for request this should not be reached
        -- if count == #requests then
        --   running = false
        --   requests = nil
        --   variables = nil
        -- end

        -- update_status_callback(running, requests)
        update_status_callback()
        update_view_callback()

        if count == #requests then
          update_status_callback = nil
          update_view_callback = nil
          running = false
          requests = nil
          variables = nil
        end
      end
    )
  )
  vim.loop.read_start(stdout, callback)
  vim.loop.read_start(stderr, callback)
end

function M.go()
  for i = 1, #requests do
    local request = requests[i]
    if request:is_queued() or request:is_missing_data() then
      M.async_curl(request)
    end
  end
end

function M.make_requests(reqs, vars, status_handler, view_handler)
  -- some variables for tracking state
  running = true
  count = 0
  requests = reqs
  variables = vars
  -- bind callback with args to single func with no args
  update_status_callback = function()
    status_handler(running, requests)
  end
  -- update_status_callback = status_handler

  update_view_callback = function()
    view_handler(requests)
  end

  M.go()
end

return M

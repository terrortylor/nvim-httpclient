require('nvim-httpclient').setup()

describe('variables', function()

  before_each(function()
  end)

  after_each(function()
  end)

  local test_table = {
    {
      line = 3,
      curl = "curl -X GET https://jsonplaceholder.typicode.com/todos/1"
    },
    {
      line = 6,
      curl = 'curl -X POST https://jsonplaceholder.typicode.com/todos --data userId=123&title=2&completed=false'
    },
  }

  for _,t in pairs(test_table) do
    it("Line: " .. t.line, function()
      vim.cmd("e tests/input/var_extract_example.http")
      vim.api.nvim_win_set_cursor(0, {t.line,0})

      vim.cmd("HttpclientInspectCurrent")

      local curl = vim.api.nvim_command_output("echo @+")
      assert.equal(t.curl, curl)
    end)
  end

  it("should run queries using variables", function()
      vim.cmd("e tests/input/var_extract_example.http")

      vim.cmd("HttpclientRunFile")
      vim.wait("1000")

      local result = vim.api.nvim_buf_get_lines(
      4, 0, vim.api.nvim_buf_line_count(4), false
      )

      local expected = {}
      local filehandler, err = io.open("tests/snapshots/var_extract_example.txt")
      if err then print("Couldn't read snapshots file"); return; end

      while true do
        local line = filehandler:read()
        if line == nil then break end
        table.insert(expected, line)
      end

      assert.are.same(expected, result)
  end)
end)

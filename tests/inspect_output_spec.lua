require('nvim-httpclient').setup()

describe('parse http', function()

  before_each(function()
  end)

  after_each(function()
  end)

  -- TODO move to another test
  it("Should set filetype", function()
    vim.cmd("e tests/input/examples.http")
    local filetype = vim.bo.filetype
    assert.equals("http", filetype)
  end)

  local test_table = {
    {
      line = 1,
      curl = "curl -X GET http://example.com"
    },
    {
      line = 3,
      curl = "curl -X GET https://example.com"
    },
    {
      line = 5,
      curl = "curl -X GET http://www.example.com"
    },
    {
      line = 7,
      curl = "curl -X GET https://www.example.com"
    },
    {
      line = 9,
      curl = "curl -X GET https://example.com/path"
    },
    {
      line = 12,
      curl = "curl -X GET https://example.com/path?id=12&goat=cheese"
    },
    {
      line = 17,
      curl = "curl -X GET https://example.com/path?id=12 -H 'Accept: application/json'"
    },
    {
      line = 22,
      curl = "curl -X POST example.com/goats --data name=cheeseman -H 'Content-Type: application/json'"
    },
    {
      line = 27,
      curl = "curl -X POST example.com/goats --data @input.txt -H 'Content-Type: application/json'"
    },
    {
      line = 32,
      curl = "curl -X POST https://cheese.example.com:443/goats --data @input.txt",
    },
    {
      line = 37,
      -- luacheck: ignore
      curl = "curl -X POST https://cheese.example.com:443/goats/soft?api-version=2022&itchy=%2Ftriggers%2F --data @input.txt",
    },
  }

  for _,t in pairs(test_table) do
    it("Line: " .. t.line, function()
      vim.cmd("e tests/input/examples.http")
      vim.api.nvim_win_set_cursor(0, {t.line,0})

      vim.cmd("HttpclientInspectCurrent")

      local curl = vim.api.nvim_command_output("echo @+")
      assert.equal(t.curl, curl)
    end)
  end
end)

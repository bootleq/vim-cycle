vim.api.nvim_create_user_command("DummySetup", function(params)
  local dummy = require('dummy')

  dummy.setup({
    should_ask = function(_, bufname)
      print("foo bar\" \\\"

              2000 ")
    end,
  })

  vim.cmd([[cnoreabbrev dm "Dummy"]])
end, {})

vim.keymap.set({'n', 'x'}, "[foo\"bar]", '<Nop>')

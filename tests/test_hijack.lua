local MiniTest = require("mini.test")

local T = MiniTest.new_set()

local hijack = require("tiny-glimmer.hijack")

T["hijack"] = MiniTest.new_set()

T["hijack"]["hijacks normal mode keymapping"] = function()
  local executed = false
  local command = function()
    executed = true
  end

  hijack.hijack("n", "test_key", nil, command)

  local mapping = vim.fn.maparg("test_key", "n", false, true)
  MiniTest.expect.equality(type(mapping), "table")
  MiniTest.expect.equality(mapping.lhs, "test_key")

  vim.api.nvim_del_keymap("n", "test_key")
end

T["hijack"]["handles whitespace in mode parameter"] = function()
  local command = function() end

  hijack.hijack("  n  ", "test_key2", nil, command)

  local mapping = vim.fn.maparg("test_key2", "n", false, true)
  MiniTest.expect.equality(type(mapping), "table")

  vim.api.nvim_del_keymap("n", "test_key2")
end

T["hijack"]["defaults to normal mode when mode is empty"] = function()
  local command = function() end

  hijack.hijack("", "test_key3", nil, command)

  local mapping = vim.fn.maparg("test_key3", "n", false, true)
  MiniTest.expect.equality(type(mapping), "table")

  vim.api.nvim_del_keymap("n", "test_key3")
end

T["hijack"]["creates noremap mapping"] = function()
  local command = function() end

  hijack.hijack("n", "test_key4", nil, command)

  local mapping = vim.fn.maparg("test_key4", "n", false, true)
  MiniTest.expect.equality(mapping.noremap, 1)

  vim.api.nvim_del_keymap("n", "test_key4")
end

T["hijack"]["mapping has callback function"] = function()
  local command = function() end

  hijack.hijack("n", "test_key5", nil, command)

  local mapping = vim.fn.maparg("test_key5", "n", false, true)
  MiniTest.expect.equality(type(mapping.callback), "function")

  vim.api.nvim_del_keymap("n", "test_key5")
end

return T

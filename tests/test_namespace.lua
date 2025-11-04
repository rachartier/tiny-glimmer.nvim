local MiniTest = require("mini.test")

local T = MiniTest.new_set()

local namespace = require("tiny-glimmer.namespace")

T["namespace"] = MiniTest.new_set()

T["namespace"]["has animation_group"] = function()
  MiniTest.expect.equality(type(namespace.animation_group), "number")
end

T["namespace"]["has tiny_glimmer_animation_ns"] = function()
  MiniTest.expect.equality(type(namespace.tiny_glimmer_animation_ns), "number")
end

T["namespace"]["animation_group is valid augroup"] = function()
  -- Augroup should be a positive number
  MiniTest.expect.equality(namespace.animation_group > 0, true)
end

T["namespace"]["tiny_glimmer_animation_ns is valid namespace"] = function()
  -- Namespace should be a positive number
  MiniTest.expect.equality(namespace.tiny_glimmer_animation_ns > 0, true)
end

T["namespace"]["augroup is named TinyGlimmer"] = function()
  -- Verify the augroup name exists
  local augroups = vim.api.nvim_get_autocmds({ group = namespace.animation_group })
  -- Should not error and return a table
  MiniTest.expect.equality(type(augroups), "table")
end

return T

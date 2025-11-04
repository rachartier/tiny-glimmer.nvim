local MiniTest = require("mini.test")
local H = require("tests.helpers")

local T = MiniTest.new_set()

-- Clear the module cache before each test
local function clear_module_cache()
  package.loaded["tiny-glimmer"] = nil
  package.loaded["tiny-glimmer.init"] = nil
  package.loaded["tiny-glimmer.setup"] = nil
  package.loaded["tiny-glimmer.api"] = nil
end

T["module structure"] = MiniTest.new_set()

T["module structure"]["returns a table"] = function()
  clear_module_cache()
  local glimmer = require("tiny-glimmer")
  MiniTest.expect.equality(type(glimmer), "table")
end

T["module structure"]["has setup function before setup"] = function()
  clear_module_cache()
  local glimmer = require("tiny-glimmer")
  MiniTest.expect.equality(type(glimmer.setup), "function")
end

T["module structure"]["has custom_remap function"] = function()
  clear_module_cache()
  local glimmer = require("tiny-glimmer")
  MiniTest.expect.equality(type(glimmer.custom_remap), "function")
end

T["setup"] = MiniTest.new_set()

T["setup"]["initializes config"] = function()
  clear_module_cache()
  local glimmer = require("tiny-glimmer")

  glimmer.setup({})

  MiniTest.expect.equality(type(glimmer.config), "table")
  MiniTest.expect.no_equality(glimmer.config, nil)
end

T["setup"]["loads API methods"] = function()
  clear_module_cache()
  local glimmer = require("tiny-glimmer")

  glimmer.setup({})

  -- Check all API methods are loaded
  local api_methods = {
    "enable", "disable", "toggle", "change_hl", "get_background_hl",
    "search_next", "search_prev", "search_under_cursor",
    "paste", "Paste", "undo", "redo"
  }

  for _, method in ipairs(api_methods) do
    MiniTest.expect.equality(type(glimmer[method]), "function", "Missing method: " .. method)
  end
end

T["setup"]["accepts user options"] = function()
  clear_module_cache()
  local glimmer = require("tiny-glimmer")

  glimmer.setup({ enabled = false })

  MiniTest.expect.equality(glimmer.config.enabled, false)
end

T["setup"]["merges with defaults"] = function()
  clear_module_cache()
  local glimmer = require("tiny-glimmer")

  glimmer.setup({ enabled = false })

  -- Should have default animations even though we only set enabled
  MiniTest.expect.equality(type(glimmer.config.animations), "table")
  MiniTest.expect.equality(type(glimmer.config.animations.fade), "table")
end

T["custom_remap"] = MiniTest.new_set()

T["custom_remap"]["accepts string map"] = function()
  clear_module_cache()
  local glimmer = require("tiny-glimmer")

  -- Should not throw error
  glimmer.custom_remap("p", "n", function() end)
end

T["custom_remap"]["accepts table map with lhs"] = function()
  clear_module_cache()
  local glimmer = require("tiny-glimmer")

  -- Should not throw error
  glimmer.custom_remap({ lhs = "p" }, "n", function() end)
end

T["custom_remap"]["accepts table map with lhs and rhs"] = function()
  clear_module_cache()
  local glimmer = require("tiny-glimmer")

  -- Should not throw error
  glimmer.custom_remap({ lhs = "p", rhs = "p" }, "n", function() end)
end

T["custom_remap"]["handles <c-r> mapping"] = function()
  clear_module_cache()
  local glimmer = require("tiny-glimmer")

  -- Should not throw error
  glimmer.custom_remap("<c-r>", "n", function() end)
end

T["hijack_done"] = MiniTest.new_set()

T["hijack_done"]["starts as false"] = function()
  clear_module_cache()
  local glimmer = require("tiny-glimmer")

  MiniTest.expect.equality(glimmer.hijack_done, false)
end

return T

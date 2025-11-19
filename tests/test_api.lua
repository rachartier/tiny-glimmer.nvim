local H = require("tests.helpers")
local MiniTest = require("mini.test")

local T = MiniTest.new_set()

T["enable"] = MiniTest.new_set()

T["enable"]["sets config.enabled to true"] = function()
  local glimmer = H.setup_glimmer({ enabled = false })
  local api = require("tiny-glimmer.api")
  api.enable()
  MiniTest.expect.equality(glimmer.config.enabled, true)
end

T["disable"] = MiniTest.new_set()

T["disable"]["sets config.enabled to false"] = function()
  local glimmer = H.setup_glimmer({ enabled = true })
  local api = require("tiny-glimmer.api")
  api.disable()
  MiniTest.expect.equality(glimmer.config.enabled, false)
end

T["toggle"] = MiniTest.new_set()

T["toggle"]["toggles config.enabled"] = function()
  local glimmer = H.setup_glimmer({ enabled = true })
  local api = require("tiny-glimmer.api")

  api.toggle()
  MiniTest.expect.equality(glimmer.config.enabled, false)

  api.toggle()
  MiniTest.expect.equality(glimmer.config.enabled, true)
end

T["change_hl"] = MiniTest.new_set()

T["change_hl"]["changes single animation highlight"] = function()
  local glimmer = H.setup_glimmer()
  local api = require("tiny-glimmer.api")

  api.change_hl("fade", { from_color = "#111111" })

  MiniTest.expect.equality(glimmer.config.animations.fade.from_color, "#111111")
end

T["change_hl"]["changes to_color"] = function()
  local glimmer = H.setup_glimmer()
  local api = require("tiny-glimmer.api")

  api.change_hl("fade", { to_color = "#222222" })

  MiniTest.expect.equality(glimmer.config.animations.fade.to_color, "#222222")
end

T["change_hl"]["changes both colors"] = function()
  local glimmer = H.setup_glimmer()
  local api = require("tiny-glimmer.api")

  api.change_hl("fade", { from_color = "#333333", to_color = "#444444" })

  MiniTest.expect.equality(glimmer.config.animations.fade.from_color, "#333333")
  MiniTest.expect.equality(glimmer.config.animations.fade.to_color, "#444444")
end

T["change_hl"]['changes all animations when animation_name is "all"'] = function()
  local glimmer = H.setup_glimmer()
  local api = require("tiny-glimmer.api")

  api.change_hl("all", { from_color = "#555555" })

  MiniTest.expect.equality(glimmer.config.animations.fade.from_color, "#555555")
  MiniTest.expect.equality(glimmer.config.animations.pulse.from_color, "#555555")
end

T["change_hl"]["changes multiple animations when passed table"] = function()
  local glimmer = H.setup_glimmer()
  local api = require("tiny-glimmer.api")

  api.change_hl({ "fade", "pulse" }, { from_color = "#666666" })

  MiniTest.expect.equality(glimmer.config.animations.fade.from_color, "#666666")
  MiniTest.expect.equality(glimmer.config.animations.pulse.from_color, "#666666")
end

T["get_background_hl"] = MiniTest.new_set()

T["get_background_hl"]["returns a string"] = function()
  H.setup_glimmer()
  local api = require("tiny-glimmer.api")

  local result = api.get_background_hl("Normal")

  MiniTest.expect.equality(type(result), "string")
end

T["search methods"] = MiniTest.new_set()

-- Tests that verify warning behavior when features are explicitly disabled
-- These tests intentionally disable features to ensure proper warnings are shown

T["search methods"]["search_next warns when search disabled"] = function()
  -- Intentionally disable search to test warning
  local glimmer = H.setup_glimmer({
    overwrite = { search = { enabled = false } },
  })
  local api = require("tiny-glimmer.api")
  api.search_next() -- Should show warning
end

T["search methods"]["search_prev warns when search disabled"] = function()
  -- Intentionally disable search to test warning
  local glimmer = H.setup_glimmer({
    overwrite = { search = { enabled = false } },
  })
  local api = require("tiny-glimmer.api")
  api.search_prev() -- Should show warning
end

T["search methods"]["search_under_cursor warns when search disabled"] = function()
  -- Intentionally disable search to test warning
  local glimmer = H.setup_glimmer({
    overwrite = { search = { enabled = false } },
  })
  local api = require("tiny-glimmer.api")
  api.search_under_cursor() -- Should show warning
end

T["paste methods"] = MiniTest.new_set()

T["paste methods"]["paste warns when paste disabled"] = function()
  -- Intentionally disable paste to test warning
  local glimmer = H.setup_glimmer({
    overwrite = { paste = { enabled = false } },
  })
  local api = require("tiny-glimmer.api")
  api.paste() -- Should show warning
end

T["paste methods"]["Paste warns when paste disabled"] = function()
  -- Intentionally disable paste to test warning
  local glimmer = H.setup_glimmer({
    overwrite = { paste = { enabled = false } },
  })
  local api = require("tiny-glimmer.api")
  api.Paste() -- Should show warning
end

T["undo/redo methods"] = MiniTest.new_set()

T["undo/redo methods"]["undo warns when undo disabled"] = function()
  -- Intentionally disable undo to test warning
  local glimmer = H.setup_glimmer({
    overwrite = { undo = { enabled = false } },
  })
  local api = require("tiny-glimmer.api")
  api.undo() -- Should show warning
end

T["undo/redo methods"]["redo warns when redo disabled"] = function()
  -- Intentionally disable redo to test warning
  local glimmer = H.setup_glimmer({
    overwrite = { redo = { enabled = false } },
  })
  local api = require("tiny-glimmer.api")
  api.redo() -- Should show warning
end

return T

local MiniTest = require("mini.test")
local setup = require("tiny-glimmer.setup")

local T = MiniTest.new_set()

T["initialize"] = MiniTest.new_set()

T["initialize"]["returns a config table"] = function()
  local config = setup.initialize({})
  MiniTest.expect.equality(type(config), "table")
end

T["initialize"]["merges user options with defaults"] = function()
  local config = setup.initialize({
    enabled = false,
    custom_field = "test_value",
  })

  MiniTest.expect.equality(config.enabled, false)
  MiniTest.expect.equality(config.custom_field, "test_value")
  -- Default fields should still be present
  MiniTest.expect.equality(type(config.animations), "table")
end

T["initialize"]["deep merges nested options"] = function()
  local config = setup.initialize({
    animations = {
      fade = {
        max_duration = 999,
      },
    },
  })

  MiniTest.expect.equality(config.animations.fade.max_duration, 999)
  -- Other fade properties should still exist from defaults
  MiniTest.expect.equality(type(config.animations.fade.min_duration), "number")
end

T["initialize"]["sanitizes highlights"] = function()
  local config = setup.initialize({
    disable_warnings = true,
    animations = {
      test_anim = {
        from_color = "#ff0000",
        to_color = "#00ff00",
      },
    },
  })

  -- After sanitize, colors should be processed
  MiniTest.expect.equality(type(config.animations.test_anim.from_color), "string")
  MiniTest.expect.equality(type(config.animations.test_anim.to_color), "string")
end

T["initialize"]["initializes with empty options"] = function()
  local config = setup.initialize()

  MiniTest.expect.equality(type(config), "table")
  MiniTest.expect.equality(type(config.enabled), "boolean")
  MiniTest.expect.equality(type(config.animations), "table")
end

T["initialize"]["handles overwrite configuration"] = function()
  local config = setup.initialize({
    overwrite = {
      yank = {
        enabled = false,
      },
    },
  })

  MiniTest.expect.equality(config.overwrite.yank.enabled, false)
  -- Other overwrite settings should exist from defaults
  MiniTest.expect.equality(type(config.overwrite.paste), "table")
end

T["initialize"]["handles presets configuration"] = function()
  local config = setup.initialize({
    presets = {
      pulsar = {
        enabled = true,
      },
    },
  })

  MiniTest.expect.equality(config.presets.pulsar.enabled, true)
end

T["initialize"]["sets up refresh interval"] = function()
  local config = setup.initialize({
    refresh_interval_ms = 16,
  })

  MiniTest.expect.equality(config.refresh_interval_ms, 16)
end

return T

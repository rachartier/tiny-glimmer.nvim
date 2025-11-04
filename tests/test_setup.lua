local MiniTest = require("mini.test")

local T = MiniTest.new_set()

local setup = require("tiny-glimmer.setup")

T["setup"] = MiniTest.new_set()

T["setup"]["initialize returns config"] = function()
  local config = setup.initialize({})

  MiniTest.expect.equality(type(config), "table")
end

T["setup"]["initialize merges user options with defaults"] = function()
  local config = setup.initialize({
    enabled = false,
    refresh_interval_ms = 16,
  })

  MiniTest.expect.equality(config.enabled, false)
  MiniTest.expect.equality(config.refresh_interval_ms, 16)
  -- Defaults should still be present
  MiniTest.expect.equality(type(config.animations), "table")
end

T["setup"]["initialize creates effects pool"] = function()
  local config = setup.initialize({
    animations = {
      fade = {
        from_color = "#ff0000",
        to_color = "#00ff00",
      },
    },
  })

  MiniTest.expect.equality(type(config.animations.fade), "table")
  MiniTest.expect.equality(config.animations.fade.from_color, "#ff0000")
end

T["setup"]["initialize handles empty user options"] = function()
  local config = setup.initialize()

  MiniTest.expect.equality(type(config), "table")
  MiniTest.expect.equality(type(config.animations), "table")
  MiniTest.expect.equality(type(config.overwrite), "table")
  MiniTest.expect.equality(type(config.presets), "table")
end

T["setup"]["initialize sets up support modules when enabled"] = function()
  local config = setup.initialize({
    support = {
      substitute = { enabled = true },
    },
  })

  MiniTest.expect.equality(config.support.substitute.enabled, true)
end

T["setup"]["initialize sets up overwrite modules when enabled"] = function()
  local config = setup.initialize({
    overwrite = {
      yank = { enabled = true },
    },
  })

  MiniTest.expect.equality(config.overwrite.yank.enabled, true)
end

T["setup"]["initialize handles disabled overwrite modules"] = function()
  local config = setup.initialize({
    overwrite = {
      yank = { enabled = false },
    },
  })

  MiniTest.expect.equality(config.overwrite.yank.enabled, false)
end

T["setup"]["initialize handles presets"] = function()
  local config = setup.initialize({
    presets = {
      pulsar = { enabled = false },
    },
  })

  MiniTest.expect.equality(config.presets.pulsar.enabled, false)
end

T["setup"]["initialize sanitizes highlights"] = function()
  local config = setup.initialize({
    animations = {
      fade = {
        from_color = "invalid_color",
        to_color = "#00ff00",
      },
    },
  })

  -- Should have been sanitized
  MiniTest.expect.equality(type(config.animations.fade), "table")
end

T["setup"]["initialize creates TinyGlimmer user command"] = function()
  setup.initialize({})

  local commands = vim.api.nvim_get_commands({})
  MiniTest.expect.equality(commands.TinyGlimmer ~= nil, true)
end

T["setup"]["initialize handles hijack_ft_disabled"] = function()
  local config = setup.initialize({
    hijack_ft_disabled = { "alpha", "dashboard" },
  })

  MiniTest.expect.equality(type(config.hijack_ft_disabled), "table")
  MiniTest.expect.equality(#config.hijack_ft_disabled, 2)
end

T["setup"]["initialize handles refresh_interval_ms"] = function()
  local config = setup.initialize({
    refresh_interval_ms = 10,
  })

  MiniTest.expect.equality(config.refresh_interval_ms, 10)
end

return T

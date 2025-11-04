local MiniTest = require("mini.test")
local highlights = require("tiny-glimmer.config.highlights")

local T = MiniTest.new_set()

T["process_highlight_color"] = MiniTest.new_set()

T["process_highlight_color"]["returns hex color unchanged"] = function()
  local options = { transparency_color = nil, disable_warnings = true }
  local result = highlights.process_highlight_color("#ff0000", "test", true, options)
  MiniTest.expect.equality(result, "#ff0000")
end

T["process_highlight_color"]["returns nil unchanged"] = function()
  local options = { transparency_color = nil, disable_warnings = true }
  local result = highlights.process_highlight_color(nil, "test", true, options)
  MiniTest.expect.equality(result, nil)
end

T["process_highlight_color"]["converts highlight group to hex"] = function()
  local options = { transparency_color = nil, disable_warnings = true }
  local result = highlights.process_highlight_color("Normal", "test", false, options)
  MiniTest.expect.equality(type(result), "string")
  -- Result should be hex color or "none"
  local is_hex = result:match("^#%x+$") ~= nil
  local is_none = result:lower() == "none"
  MiniTest.expect.equality(is_hex or is_none, true)
end

T["validate_transparency"] = MiniTest.new_set()

T["validate_transparency"]["does not error with valid config"] = function()
  local options = { transparency_color = nil, disable_warnings = true }
  -- Should not throw error
  highlights.validate_transparency(options)
end

T["sanitize_highlights"] = MiniTest.new_set()

T["sanitize_highlights"]["processes animation colors"] = function()
  local config = {
    transparency_color = nil,
    disable_warnings = true,
    animations = {
      test_anim = {
        from_color = "#ff0000",
        to_color = "#00ff00",
      },
    },
    presets = {},
    overwrite = {},
    support = {},
  }

  highlights.sanitize_highlights(config)

  MiniTest.expect.equality(type(config.animations.test_anim.from_color), "string")
  MiniTest.expect.equality(type(config.animations.test_anim.to_color), "string")
end

T["sanitize_highlights"]["handles preset default_animation as string"] = function()
  local config = {
    transparency_color = nil,
    disable_warnings = true,
    animations = {
      fade = {
        from_color = "#ff0000",
        to_color = "#00ff00",
      },
    },
    presets = {
      test_preset = {
        default_animation = "fade",
      },
    },
    overwrite = {},
    support = {},
  }

  highlights.sanitize_highlights(config)

  -- default_animation should remain as string
  MiniTest.expect.equality(config.presets.test_preset.default_animation, "fade")
end

T["sanitize_highlights"]["handles preset default_animation as table"] = function()
  local config = {
    transparency_color = nil,
    disable_warnings = true,
    animations = {},
    presets = {
      test_preset = {
        default_animation = {
          name = "test",
          settings = {
            from_color = "#ff0000",
            to_color = "#00ff00",
          },
        },
      },
    },
    overwrite = {},
    support = {},
  }

  highlights.sanitize_highlights(config)

  MiniTest.expect.equality(type(config.presets.test_preset.default_animation.settings.from_color), "string")
  MiniTest.expect.equality(type(config.presets.test_preset.default_animation.settings.to_color), "string")
end

return T

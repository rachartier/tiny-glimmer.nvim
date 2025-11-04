local MiniTest = require("mini.test")
local defaults = require("tiny-glimmer.config.defaults")

local T = MiniTest.new_set()

T["defaults"] = MiniTest.new_set()

T["defaults"]["returns a table"] = function()
  MiniTest.expect.equality(type(defaults), "table")
end

T["defaults"]["has enabled field"] = function()
  MiniTest.expect.equality(type(defaults.enabled), "boolean")
  MiniTest.expect.equality(defaults.enabled, true)
end

T["defaults"]["has overwrite configuration"] = function()
  MiniTest.expect.equality(type(defaults.overwrite), "table")
  MiniTest.expect.equality(type(defaults.overwrite.auto_map), "boolean")
end

T["defaults"]["has animations configuration"] = function()
  MiniTest.expect.equality(type(defaults.animations), "table")

  -- Check for required animations
  local required_animations =
    { "fade", "reverse_fade", "bounce", "left_to_right", "pulse", "rainbow", "custom" }
  for _, anim_name in ipairs(required_animations) do
    MiniTest.expect.equality(
      type(defaults.animations[anim_name]),
      "table",
      "Missing animation: " .. anim_name
    )
  end
end

T["defaults"]["fade animation has required fields"] = function()
  local fade = defaults.animations.fade

  MiniTest.expect.equality(type(fade.max_duration), "number")
  MiniTest.expect.equality(type(fade.min_duration), "number")
  MiniTest.expect.equality(type(fade.easing), "string")
  MiniTest.expect.equality(type(fade.from_color), "string")
  MiniTest.expect.equality(type(fade.to_color), "string")
end

T["defaults"]["has presets configuration"] = function()
  MiniTest.expect.equality(type(defaults.presets), "table")
  MiniTest.expect.equality(type(defaults.presets.pulsar), "table")
end

T["defaults"]["has support configuration"] = function()
  MiniTest.expect.equality(type(defaults.support), "table")
  MiniTest.expect.equality(type(defaults.support.substitute), "table")
end

T["defaults"]["has refresh_interval_ms"] = function()
  MiniTest.expect.equality(type(defaults.refresh_interval_ms), "number")
  MiniTest.expect.no_equality(defaults.refresh_interval_ms, nil)
  MiniTest.expect.equality(defaults.refresh_interval_ms > 0, true)
end

T["defaults"]["has virt_text configuration"] = function()
  MiniTest.expect.equality(type(defaults.virt_text), "table")
  MiniTest.expect.equality(type(defaults.virt_text.priority), "number")
end

T["defaults"]["has hijack_ft_disabled"] = function()
  MiniTest.expect.equality(type(defaults.hijack_ft_disabled), "table")
end

return T

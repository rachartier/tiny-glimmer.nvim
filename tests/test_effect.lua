local MiniTest = require("mini.test")

local T = MiniTest.new_set()

T["Effect"] = MiniTest.new_set()

T["Effect"]["new creates an Effect instance"] = function()
  local Effect = require("tiny-glimmer.animation.effect")

  local settings = { test = "value" }
  local update_fn = function() end
  local effect = Effect.new(settings, update_fn)

  MiniTest.expect.equality(type(effect), "table")
  MiniTest.expect.equality(effect.settings, settings)
  MiniTest.expect.equality(effect.update_fn, update_fn)
end

T["Effect"]["new accepts builder function"] = function()
  local Effect = require("tiny-glimmer.animation.effect")

  local builder = function(self)
    return { initialized = true }
  end

  local effect = Effect.new({}, function() end, builder)
  MiniTest.expect.equality(effect._starter_builder, builder)
end

T["Effect"]["build_starter calls builder function"] = function()
  local Effect = require("tiny-glimmer.animation.effect")

  local builder_called = false
  local builder = function(_)
    builder_called = true
    return { test = "starter_data" }
  end

  local effect = Effect.new({}, function() end, builder)
  effect:build_starter()

  MiniTest.expect.equality(builder_called, true)
  MiniTest.expect.equality(type(effect.starter), "table")
  MiniTest.expect.equality(effect.starter.test, "starter_data")
end

T["Effect"]["build_starter does nothing without builder"] = function()
  local Effect = require("tiny-glimmer.animation.effect")

  local effect = Effect.new({}, function() end)
  effect:build_starter()

  MiniTest.expect.equality(effect.starter, nil)
end

T["Effect"]["update_settings updates settings"] = function()
  local Effect = require("tiny-glimmer.animation.effect")

  local effect = Effect.new({ old = "value" }, function() end)
  effect:update_settings({ new = "value" })

  MiniTest.expect.equality(effect.settings.new, "value")
  MiniTest.expect.equality(effect.settings.old, nil)
end

T["Effect"]["builder receives self as argument"] = function()
  local Effect = require("tiny-glimmer.animation.effect")

  local received_self = nil
  local builder = function(self)
    received_self = self
    return {}
  end

  local settings = { color = "#ff0000" }
  local effect = Effect.new(settings, function() end, builder)
  effect:build_starter()

  MiniTest.expect.equality(received_self, effect)
  if received_self and received_self.settings then
    MiniTest.expect.equality(received_self.settings.color, "#ff0000")
  end
end

return T

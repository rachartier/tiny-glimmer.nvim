local MiniTest = require("mini.test")

local T = MiniTest.new_set()

T["GlimmerAnimation"] = MiniTest.new_set()

T["GlimmerAnimation"]["new creates a GlimmerAnimation instance"] = function()
  local Effect = require("tiny-glimmer.animation.effect")
  local GlimmerAnimation = require("tiny-glimmer.glimmer_animation")

  local effect = Effect.new({ easing = "linear" }, function() end)
  local range = { start_line = 0, start_col = 0, end_line = 0, end_col = 10 }

  local animation = GlimmerAnimation.new(effect, { range = range })

  MiniTest.expect.equality(type(animation), "table")
  MiniTest.expect.equality(animation.range, range)
  MiniTest.expect.equality(animation.active, false)
  MiniTest.expect.equality(type(animation.id), "number")
end

T["GlimmerAnimation"]["new requires range in opts"] = function()
  local Effect = require("tiny-glimmer.animation.effect")
  local GlimmerAnimation = require("tiny-glimmer.glimmer_animation")

  local effect = Effect.new({}, function() end)

  local success, err = pcall(function()
    GlimmerAnimation.new(effect, {})
  end)

  MiniTest.expect.equality(success, false)
  MiniTest.expect.equality(type(err), "string")
end

T["GlimmerAnimation"]["new accepts overwrite colors"] = function()
  local Effect = require("tiny-glimmer.animation.effect")
  local GlimmerAnimation = require("tiny-glimmer.glimmer_animation")

  local effect = Effect.new({}, function() end)
  local range = { start_line = 0, start_col = 0, end_line = 0, end_col = 10 }

  local animation = GlimmerAnimation.new(effect, {
    range = range,
    overwrite_from_color = "#ff0000",
    overwrite_to_color = "#00ff00",
  })

  MiniTest.expect.equality(animation.overwrite_from_color, "#ff0000")
  MiniTest.expect.equality(animation.overwrite_to_color, "#00ff00")
end

T["GlimmerAnimation"]["new accepts loop options"] = function()
  local Effect = require("tiny-glimmer.animation.effect")
  local GlimmerAnimation = require("tiny-glimmer.glimmer_animation")

  local effect = Effect.new({}, function() end)
  local range = { start_line = 0, start_col = 0, end_line = 0, end_col = 10 }

  local animation = GlimmerAnimation.new(effect, {
    range = range,
    loop = true,
    loop_count = 5,
  })

  MiniTest.expect.equality(animation.loop, true)
  MiniTest.expect.equality(animation.loop_count, 5)
end

T["GlimmerAnimation"]["get_hl_group returns highlight group"] = function()
  local Effect = require("tiny-glimmer.animation.effect")
  local GlimmerAnimation = require("tiny-glimmer.glimmer_animation")

  local effect = Effect.new({}, function() end)
  local range = { start_line = 0, start_col = 0, end_line = 0, end_col = 10 }

  local animation = GlimmerAnimation.new(effect, { range = range })
  local hl_group = animation:get_hl_group()

  MiniTest.expect.equality(type(hl_group), "string")
  MiniTest.expect.equality(string.match(hl_group, "TinyGlimmerAnimationHighlight_") ~= nil, true)
end

T["GlimmerAnimation"]["get_overwrite_hl_group returns overwrite highlight group"] = function()
  local Effect = require("tiny-glimmer.animation.effect")
  local GlimmerAnimation = require("tiny-glimmer.glimmer_animation")

  local effect = Effect.new({}, function() end)
  local range = { start_line = 0, start_col = 0, end_line = 0, end_col = 10 }

  local animation = GlimmerAnimation.new(effect, { range = range })
  local hl_group = animation:get_overwrite_hl_group()

  MiniTest.expect.equality(type(hl_group), "string")
  MiniTest.expect.equality(
    string.match(hl_group, "TinyGlimmerAnimationOverwriteHighlight_") ~= nil,
    true
  )
end

T["GlimmerAnimation"]["stop sets active to false"] = function()
  local Effect = require("tiny-glimmer.animation.effect")
  local GlimmerAnimation = require("tiny-glimmer.glimmer_animation")

  local effect = Effect.new({}, function() end)
  local range = { start_line = 0, start_col = 0, end_line = 0, end_col = 10 }

  local animation = GlimmerAnimation.new(effect, { range = range })
  animation.active = true
  animation:stop()

  MiniTest.expect.equality(animation.active, false)
end

T["GlimmerAnimation"]["update_effect returns progress"] = function()
  local Effect = require("tiny-glimmer.animation.effect")
  local GlimmerAnimation = require("tiny-glimmer.glimmer_animation")

  local update_fn = function(_, progress, _)
    return "#ff0000", progress
  end

  local effect = Effect.new({ easing = "linear" }, update_fn)
  local range = { start_line = 0, start_col = 0, end_line = 0, end_col = 10 }

  local animation = GlimmerAnimation.new(effect, { range = range })
  local progress = animation:update_effect(0.5)

  MiniTest.expect.equality(progress, 0.5)
end

return T

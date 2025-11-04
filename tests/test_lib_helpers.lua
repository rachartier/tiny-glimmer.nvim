local AnimationFactory = require("tiny-glimmer.animation.factory")
local MiniTest = require("mini.test")
local lib_helpers = require("tiny-glimmer.lib_helpers")

local T = MiniTest.new_set()

T["lib_helpers"] = MiniTest.new_set()

-- Test normalize_color
T["lib_helpers"]["normalize_color returns hex unchanged"] = function()
  local result = lib_helpers.normalize_color("#ff0000")
  MiniTest.expect.equality(result, "#ff0000")
end

T["lib_helpers"]["normalize_color converts highlight group"] = function()
  -- Mock vim.api
  local original_get_hl = vim.api.nvim_get_hl
  vim.api.nvim_get_hl = function(ns_id, opts)
    return { bg = 16711680 } -- #ff0000 in decimal
  end

  local result = lib_helpers.normalize_color("Error")
  MiniTest.expect.equality(result, "#FF0000")

  vim.api.nvim_get_hl = original_get_hl
end

-- Test check_enabled
T["lib_helpers"]["check_enabled returns true when enabled"] = function()
  -- Mock the config
  local original_config = package.loaded["tiny-glimmer"]
  package.loaded["tiny-glimmer"] = { config = { enabled = true } }

  local result = lib_helpers.check_enabled()
  MiniTest.expect.equality(result, true)

  package.loaded["tiny-glimmer"] = original_config
end

T["lib_helpers"]["check_enabled returns false when disabled"] = function()
  -- Mock the config
  local original_config = package.loaded["tiny-glimmer"]
  package.loaded["tiny-glimmer"] = { config = { enabled = false } }

  local result = lib_helpers.check_enabled()
  MiniTest.expect.equality(result, false)

  package.loaded["tiny-glimmer"] = original_config
end

T["lib_helpers"]["check_enabled returns true when config nil"] = function()
  -- Mock the config
  local original_config = package.loaded["tiny-glimmer"]
  package.loaded["tiny-glimmer"] = { config = nil }

  local result = lib_helpers.check_enabled()
  MiniTest.expect.equality(result, true)

  package.loaded["tiny-glimmer"] = original_config
end

-- Test process_effect_config
T["lib_helpers"]["process_effect_config with string effect"] = function()
  AnimationFactory.instance = nil
  AnimationFactory.initialize(
    nil,
    { fade = { settings = { max_duration = 300, from_color = "#ffffff", to_color = "#000000" } } }
  )

  local merged_settings, effect_name =
    lib_helpers.process_effect_config("fade", { max_duration = 500 })

  MiniTest.expect.equality(effect_name, "fade")
  MiniTest.expect.equality(merged_settings.max_duration, 500)
  MiniTest.expect.equality(merged_settings.from_color, "#ffffff")
  MiniTest.expect.equality(merged_settings.to_color, "#000000")
end

T["lib_helpers"]["process_effect_config with table effect"] = function()
  AnimationFactory.instance = nil
  AnimationFactory.initialize(
    nil,
    { fade = { settings = { max_duration = 300, from_color = "#ffffff", to_color = "#000000" } } }
  )

  local merged_settings, effect_name = lib_helpers.process_effect_config(
    { name = "fade", settings = { max_duration = 400 } },
    { easing = "linear" }
  )

  MiniTest.expect.equality(effect_name, "fade")
  MiniTest.expect.equality(merged_settings.max_duration, 400)
  MiniTest.expect.equality(merged_settings.easing, "linear")
  MiniTest.expect.equality(merged_settings.from_color, "#ffffff")
end

T["lib_helpers"]["process_effect_config throws error for unknown effect"] = function()
  AnimationFactory.instance = nil
  AnimationFactory.initialize(nil, { fade = { settings = {} } })

  MiniTest.expect.error(function()
    lib_helpers.process_effect_config("unknown", {})
  end, "TinyGlimmer: Unknown effect: unknown")
end

-- Test create_animation_settings
T["lib_helpers"]["create_animation_settings creates settings"] = function()
  local merged_settings = {
    max_duration = 500,
    from_color = "#ff0000",
    to_color = "#00ff00",
    easing = "linear",
  }
  local opts = {
    loop = true,
    loop_count = 3,
  }

  local result = lib_helpers.create_animation_settings(merged_settings, opts)

  MiniTest.expect.equality(result.duration, 500)
  MiniTest.expect.equality(result.from_color, "#ff0000")
  MiniTest.expect.equality(result.to_color, "#00ff00")
  MiniTest.expect.equality(result.easing, "linear")
  MiniTest.expect.equality(result.loop, true)
  MiniTest.expect.equality(result.loop_count, 3)
end

return T

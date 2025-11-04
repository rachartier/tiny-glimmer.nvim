---@class TinyGlimmerLibHelpers
---@field process_effect_config function Process effect configuration from params
---@field check_enabled function Check if the plugin is enabled
---@field normalize_color function Normalize color to hex format
---@field create_animation_settings function Create animation settings from effect config

local M = {}

local AnimationFactory = require("tiny-glimmer.animation.factory")
local utils = require("tiny-glimmer.utils")

--- Normalize color to hex format
---@param color string Color hex or highlight group name
---@return string hex_color
function M.normalize_color(color)
  if color:match("^#") then
    return color
  end
  -- It's a highlight group
  return utils.int_to_hex(utils.get_highlight(color).bg or 0)
end

--- Check if the plugin is enabled
---@return boolean enabled
function M.check_enabled()
  local config = require("tiny-glimmer").config
  return not (config and not config.enabled)
end

--- Process effect configuration from params
---@param effect string|table Effect name or effect configuration table
---@param opts? table Optional settings override
---@return table merged_settings, string effect_name
function M.process_effect_config(effect, opts)
  opts = opts or {}
  local effect_name, effect_settings

  if type(effect) == "table" then
    effect_name = effect.name
    effect_settings = effect.settings or {}
  else
    effect_name = effect
    effect_settings = {}
  end

  local factory = AnimationFactory.get_instance()

  -- Get effect from pool
  if not factory.effect_pool[effect_name] then
    error("TinyGlimmer: Unknown effect: " .. effect_name)
  end

  local base_settings = factory.effect_pool[effect_name].settings or {}
  local merged_settings = vim.tbl_extend("force", base_settings, effect_settings, opts)

  return merged_settings, effect_name
end

--- Create animation settings from merged settings
---@param merged_settings table Merged settings
---@param opts table Original options
---@return table animation_opts
function M.create_animation_settings(merged_settings, opts)
  return {
    duration = merged_settings.max_duration or 300,
    from_color = merged_settings.from_color or "Visual",
    to_color = merged_settings.to_color or "Normal",
    easing = merged_settings.easing,
    loop = opts.loop,
    loop_count = opts.loop_count,
  }
end

return M

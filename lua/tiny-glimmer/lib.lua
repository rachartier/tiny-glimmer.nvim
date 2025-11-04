---@class TinyGlimmerLib
---@field create_animation function Create a simple animation
---@field create_line_animation function Create a line-based animation
---@field create_text_animation function Create a text-based animation
---@field create_named_animation function Create a named animation that can be stopped
---@field stop_animation function Stop a named animation
---@field easing table Available easing functions
---@field effects table Available effect types

local M = {}

local AnimationFactory = require("tiny-glimmer.animation.factory")
local Effect = require("tiny-glimmer.animation.effect")
local utils = require("tiny-glimmer.utils")

---@class AnimationRange
---@field start_line number 0-indexed start line
---@field start_col number 0-indexed start column
---@field end_line number 0-indexed end line
---@field end_col number 0-indexed end column

---@class AnimationSettings
---@field max_duration number Maximum animation duration in ms
---@field min_duration? number Minimum animation duration in ms (defaults to max_duration)
---@field chars_for_max_duration? number Character count for max duration (defaults to 10)
---@field easing? string Easing function name (defaults to "linear")
---@field from_color? string Start color (hex or highlight group)
---@field to_color? string End color (hex or highlight group)
---@field lingering_time? number Time to linger after animation completes in ms

---@class SimpleAnimationOpts
---@field range AnimationRange The range to animate
---@field duration number Animation duration in ms
---@field from_color string Start color (hex or highlight group)
---@field to_color string End color (hex or highlight group)
---@field easing? string Easing function name (defaults to "linear")
---@field effect? string Effect type (defaults to "fade")
---@field on_complete? function Callback when animation completes

---@class CustomEffectOpts
---@field settings AnimationSettings Effect settings
---@field update_fn function(self, progress: number, ease: string): string, number Function that returns color and progress
---@field builder? function(self): table Optional function to build starter data

local initialized = false
local default_effects = {}

--- Initialize the library with default effects
local function ensure_initialized()
  if initialized then
    return
  end

  -- Initialize with minimal config if not already done
  if not AnimationFactory.instance then
    AnimationFactory.initialize({ virtual_text_priority = 2048 }, {}, 8)
  end

  -- Load default effects
  default_effects = require("tiny-glimmer.premade_effects")

  initialized = true
end

--- Normalize color to hex format
---@param color string Color hex or highlight group name
---@return string hex_color
local function normalize_color(color)
  if color:match("^#") then
    return color
  end
  -- It's a highlight group
  return utils.int_to_hex(utils.get_highlight(color).bg or 0)
end

--- Create a custom effect
---@param opts CustomEffectOpts Effect configuration
---@return table effect The created effect
function M.create_effect(opts)
  ensure_initialized()

  if not opts.update_fn then
    error("TinyGlimmer: update_fn is required for custom effects")
  end

  return Effect.new(opts.settings or {}, opts.update_fn, opts.builder)
end

--- Create a simple animation with minimal configuration
---@param opts SimpleAnimationOpts Animation options
function M.create_animation(opts)
  ensure_initialized()

  if not opts.range then
    error("TinyGlimmer: range is required")
  end

  if not opts.from_color or not opts.to_color then
    error("TinyGlimmer: from_color and to_color are required")
  end

  local effect_type = opts.effect or "fade"
  local settings = {
    max_duration = opts.duration or 300,
    min_duration = opts.duration or 300,
    chars_for_max_duration = 10,
    easing = opts.easing or "linear",
    from_color = normalize_color(opts.from_color),
    to_color = normalize_color(opts.to_color),
  }

  local animation_type = {
    name = effect_type,
    settings = settings,
  }

  local factory = AnimationFactory.get_instance()
  factory.effect_pool = factory.effect_pool or default_effects

  -- Ensure the effect exists in the pool
  if not factory.effect_pool[effect_type] then
    factory.effect_pool[effect_type] = default_effects[effect_type]
  end

  local buffer = vim.api.nvim_get_current_buf()
  local effect =
    factory:_prepare_animation_effect(buffer, animation_type, { base = { range = opts.range } })
  local animation = require("tiny-glimmer.animation.premade.text").new(
    effect,
    { base = { range = opts.range }, on_complete = opts.on_complete }
  )
  factory:_manage_animation(animation, buffer)
end

--- Create a line animation (highlights entire lines)
---@param opts SimpleAnimationOpts Animation options (start_col and end_col are ignored)
function M.create_line_animation(opts)
  ensure_initialized()

  if not opts.range then
    error("TinyGlimmer: range is required")
  end

  if not opts.from_color or not opts.to_color then
    error("TinyGlimmer: from_color and to_color are required")
  end

  local effect_type = opts.effect or "fade"
  local settings = {
    max_duration = opts.duration or 300,
    min_duration = opts.duration or 300,
    chars_for_max_duration = 10,
    easing = opts.easing or "linear",
    from_color = normalize_color(opts.from_color),
    to_color = normalize_color(opts.to_color),
  }

  local animation_type = {
    name = effect_type,
    settings = settings,
  }

  local factory = AnimationFactory.get_instance()
  factory.effect_pool = factory.effect_pool or default_effects

  -- Ensure the effect exists in the pool
  if not factory.effect_pool[effect_type] then
    factory.effect_pool[effect_type] = default_effects[effect_type]
  end

  local buffer = vim.api.nvim_get_current_buf()
  local effect =
    factory:_prepare_animation_effect(buffer, animation_type, { base = { range = opts.range } })
  local animation = require("tiny-glimmer.animation.premade.line").new(
    effect,
    { base = { range = opts.range }, on_complete = opts.on_complete }
  )
  factory:_manage_animation(animation, buffer)
end

--- Create a text animation (highlights specific character ranges)
---@param opts SimpleAnimationOpts Animation options
function M.create_text_animation(opts)
  M.create_animation(opts)
end

--- Create a named animation that can be stopped later
---@param name string Unique name for the animation
---@param opts SimpleAnimationOpts Animation options
function M.create_named_animation(name, opts)
  ensure_initialized()

  if not name then
    error("TinyGlimmer: name is required for named animations")
  end

  if not opts.range then
    error("TinyGlimmer: range is required")
  end

  if not opts.from_color or not opts.to_color then
    error("TinyGlimmer: from_color and to_color are required")
  end

  local effect_type = opts.effect or "fade"
  local settings = {
    max_duration = opts.duration or 300,
    min_duration = opts.duration or 300,
    chars_for_max_duration = 10,
    easing = opts.easing or "linear",
    from_color = normalize_color(opts.from_color),
    to_color = normalize_color(opts.to_color),
  }

  local animation_type = {
    name = effect_type,
    settings = settings,
  }

  local factory = AnimationFactory.get_instance()
  factory.effect_pool = factory.effect_pool or default_effects

  -- Ensure the effect exists in the pool
  if not factory.effect_pool[effect_type] then
    factory.effect_pool[effect_type] = default_effects[effect_type]
  end

  local buffer = vim.api.nvim_get_current_buf()
  local effect =
    factory:_prepare_animation_effect(buffer, animation_type, { base = { range = opts.range } })
  local animation = require("tiny-glimmer.animation.premade.text").new(
    effect,
    { base = { range = opts.range }, on_complete = opts.on_complete }
  )
  factory:_manage_named_animation(name, animation, buffer)
end

--- Stop a named animation
---@param name string Name of the animation to stop
function M.stop_animation(name)
  ensure_initialized()

  local factory = AnimationFactory.get_instance()
  local buffer = vim.api.nvim_get_current_buf()

  if factory.buffers[buffer] and factory.buffers[buffer].named_animations[name] then
    factory.buffers[buffer].named_animations[name]:stop()
    factory.buffers[buffer].named_animations[name] = nil
  end
end

--- Get current cursor position as a range
---@return AnimationRange
function M.get_cursor_range()
  local pos = vim.api.nvim_win_get_cursor(0)
  return {
    start_line = pos[1] - 1,
    start_col = pos[2],
    end_line = pos[1] - 1,
    end_col = pos[2] + 1,
  }
end

--- Get current visual selection as a range
---@return AnimationRange|nil
function M.get_visual_range()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  if start_pos[2] == 0 or end_pos[2] == 0 then
    return nil
  end

  return {
    start_line = start_pos[2] - 1,
    start_col = start_pos[3] - 1,
    end_line = end_pos[2] - 1,
    end_col = end_pos[3],
  }
end

--- Get the range for a specific line
---@param line number 1-indexed line number (0 for current line)
---@return AnimationRange
function M.get_line_range(line)
  line = line or 0
  if line == 0 then
    line = vim.api.nvim_win_get_cursor(0)[1]
  end

  local buffer = vim.api.nvim_get_current_buf()
  local line_content = vim.api.nvim_buf_get_lines(buffer, line - 1, line, false)[1] or ""

  return {
    start_line = line - 1,
    start_col = 0,
    end_line = line - 1,
    end_col = #line_content,
  }
end

--- Available easing functions
M.easing = {
  "linear",
  "inQuad",
  "outQuad",
  "inOutQuad",
  "outInQuad",
  "inCubic",
  "outCubic",
  "inOutCubic",
  "outInCubic",
  "inQuart",
  "outQuart",
  "inOutQuart",
  "outInQuart",
  "inQuint",
  "outQuint",
  "inOutQuint",
  "outInQuint",
  "inSine",
  "outSine",
  "inOutSine",
  "outInSine",
  "inExpo",
  "outExpo",
  "inOutExpo",
  "outInExpo",
  "inCirc",
  "outCirc",
  "inOutCirc",
  "outInCirc",
  "inElastic",
  "outElastic",
  "inOutElastic",
  "outInElastic",
  "inBack",
  "outBack",
  "inOutBack",
  "outInBack",
  "inBounce",
  "outBounce",
  "inOutBounce",
  "outInBounce",
}

--- Available effect types
M.effects = {
  "fade",
  "reverse_fade",
  "bounce",
  "left_to_right",
  "pulse",
  "rainbow",
}

return M

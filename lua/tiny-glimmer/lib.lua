---@class TinyGlimmerLib
---@field create_animation function Create a simple animation
---@field create_line_animation function Create a line-based animation
---@field create_text_animation function Create a text-based animation
---@field create_named_animation function Create a named animation that can be stopped
---@field stop_animation function Stop a named animation
---@field stop_all function Stop all running animations in current buffer
---@field get_word_range function Get range for word under cursor
---@field get_paragraph_range function Get range for current paragraph
---@field animate_word function Animate word under cursor
---@field paragraph function Animate current paragraph
---@field easing table Available easing functions
---@field effects table Available effect types

local M = {}

local AnimationFactory = require("tiny-glimmer.animation.factory")
local Effect = require("tiny-glimmer.animation.effect")
local Helpers = require("tiny-glimmer.lib_helpers")
local RangeUtils = require("tiny-glimmer.range_utils")

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
---@field loop? boolean Whether the animation should loop
---@field loop_count? number Number of times to loop (0 = infinite)

---@class CustomEffectOpts
---@field settings AnimationSettings Effect settings
---@field update_fn function(self, progress: number, ease: string): string, number Function that returns color and progress
---@field builder? function(self): table Optional function to build starter data

--- Build animation settings from opts
---@param opts SimpleAnimationOpts Animation options
---@return table settings Animation settings table
local function build_animation_settings(opts)
  return {
    max_duration = opts.duration or 300,
    min_duration = opts.duration or 300,
    chars_for_max_duration = 10,
    easing = opts.easing or "linear",
    from_color = Helpers.normalize_color(opts.from_color),
    to_color = Helpers.normalize_color(opts.to_color),
  }
end

--- Validate required animation options
---@param opts SimpleAnimationOpts Animation options
local function validate_animation_opts(opts)
  if not opts.range then
    error("TinyGlimmer: range is required")
  end
  if not opts.from_color or not opts.to_color then
    error("TinyGlimmer: from_color and to_color are required")
  end
end

--- Create a custom effect
---@param opts CustomEffectOpts Effect configuration
---@return table effect The created effect
function M.create_effect(opts)
  if not opts.update_fn then
    error("TinyGlimmer: update_fn is required for custom effects")
  end

  return Effect.new(opts.settings or {}, opts.update_fn, opts.builder)
end

--- Create a simple animation with minimal configuration
---@param opts SimpleAnimationOpts Animation options
function M.create_animation(opts)
  validate_animation_opts(opts)

  local animation_type = {
    name = opts.effect or "fade",
    settings = build_animation_settings(opts),
  }

  local factory = AnimationFactory.get_instance()
  factory:create_text_animation(animation_type, {
    base = { range = opts.range },
    on_complete = opts.on_complete,
    loop = opts.loop,
    loop_count = opts.loop_count,
  })
end

--- Create a line animation (highlights entire lines)
---@param opts SimpleAnimationOpts Animation options (start_col and end_col are ignored)
function M.create_line_animation(opts)
  validate_animation_opts(opts)

  local animation_type = {
    name = opts.effect or "fade",
    settings = build_animation_settings(opts),
  }

  local factory = AnimationFactory.get_instance()
  factory:create_line_animation(animation_type, {
    base = { range = opts.range },
    on_complete = opts.on_complete,
    loop = opts.loop,
    loop_count = opts.loop_count,
  })
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
  if not name then
    error("TinyGlimmer: name is required for named animations")
  end

  validate_animation_opts(opts)

  local animation_type = {
    name = opts.effect or "fade",
    settings = build_animation_settings(opts),
  }

  local factory = AnimationFactory.get_instance()
  local buffer = vim.api.nvim_get_current_buf()
  local effect =
    factory:_prepare_animation_effect(buffer, animation_type, { base = { range = opts.range } })
  local animation = require("tiny-glimmer.animation.premade.text").new(effect, {
    base = { range = opts.range },
    on_complete = opts.on_complete,
    loop = opts.loop,
    loop_count = opts.loop_count,
  })
  factory:_manage_named_animation(name, animation, buffer, opts.on_complete)
end

--- Stop a named animation
---@param name string Name of the animation to stop
function M.stop_animation(name)
  local factory = AnimationFactory.get_instance()
  local buffer = vim.api.nvim_get_current_buf()

  if factory.buffers[buffer] and factory.buffers[buffer].named_animations[name] then
    factory.buffers[buffer].named_animations[name]:stop()
    factory.buffers[buffer].named_animations[name] = nil
  end
end

--- Stop all running animations in current buffer
function M.stop_all()
  local factory = AnimationFactory.get_instance()
  local buffer = vim.api.nvim_get_current_buf()

  if not factory.buffers[buffer] then
    return
  end

  -- Stop all named animations
  for name, _ in pairs(factory.buffers[buffer].named_animations or {}) do
    M.stop_animation(name)
  end

  -- Stop all line animations
  for _, animation in pairs(factory.buffers[buffer].animations or {}) do
    if animation and animation.stop then
      animation:stop()
    end
  end

  -- Clear the collections
  factory.buffers[buffer].named_animations = {}
  factory.buffers[buffer].animations = {}
end

--- Get current cursor position as a range
---@return AnimationRange
function M.get_cursor_range()
  return RangeUtils.get_cursor_range()
end

--- Get current visual selection as a range
---@return AnimationRange|nil
function M.get_visual_range()
  return RangeUtils.get_visual_range()
end

--- Get the range for a specific line
---@param line number 1-indexed line number (0 for current line)
---@return AnimationRange
function M.get_line_range(line)
  return RangeUtils.get_line_range(line)
end

--- Get the yank range from the last yank operation
---@return AnimationRange|nil
function M.get_yank_range()
  return RangeUtils.get_yank_range()
end

--- Get range for word under cursor
---@return AnimationRange|nil
function M.get_word_range()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  local col = cursor[2]

  local line_text = vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
  if not line_text then
    return nil
  end

  -- Find word boundaries using Vim's keyword pattern
  local word_start = col
  local word_end = col

  -- Move backward to find word start
  while word_start > 0 and line_text:sub(word_start, word_start):match("[%w_]") do
    word_start = word_start - 1
  end
  if word_start > 0 or not line_text:sub(1, 1):match("[%w_]") then
    word_start = word_start + 1
  end

  -- Move forward to find word end
  while word_end < #line_text and line_text:sub(word_end + 1, word_end + 1):match("[%w_]") do
    word_end = word_end + 1
  end

  if word_start >= word_end then
    return nil
  end

  return {
    start_line = line,
    start_col = word_start,
    end_line = line,
    end_col = word_end + 1,
  }
end

--- Get range for current paragraph
---@return AnimationRange
function M.get_paragraph_range()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local total_lines = vim.api.nvim_buf_line_count(0)

  -- Find paragraph start (empty line above or buffer start)
  local start_line = cursor_line
  while start_line > 1 do
    local line = vim.api.nvim_buf_get_lines(0, start_line - 2, start_line - 1, false)[1]
    if line and line:match("^%s*$") then
      break
    end
    start_line = start_line - 1
  end

  -- Find paragraph end (empty line below or buffer end)
  local end_line = cursor_line
  while end_line < total_lines do
    local line = vim.api.nvim_buf_get_lines(0, end_line, end_line + 1, false)[1]
    if line and line:match("^%s*$") then
      break
    end
    end_line = end_line + 1
  end

  return {
    start_line = start_line - 1,
    start_col = 0,
    end_line = end_line - 1,
    end_col = 0,
  }
end

--- Helper: Animate cursor line with an effect
---@param effect string|table Effect name or effect configuration table
---@param opts? table Optional settings override
function M.cursor_line(effect, opts)
  if not Helpers.check_enabled() then
    return
  end

  opts = opts or {}
  local merged_settings, effect_name = Helpers.process_effect_config(effect, opts)

  M.create_line_animation({
    range = M.get_line_range(0),
    duration = merged_settings.max_duration or 300,
    from_color = merged_settings.from_color or "Visual",
    to_color = merged_settings.to_color or "Normal",
    effect = effect_name,
    easing = merged_settings.easing,
    loop = opts.loop,
    loop_count = opts.loop_count,
  })
end

--- Helper: Animate visual selection with an effect
---@param effect string|table Effect name or effect configuration table
---@param opts? table Optional settings override
function M.visual_selection(effect, opts)
  if not Helpers.check_enabled() then
    return
  end

  local range = M.get_visual_range()
  if not range then
    return
  end

  opts = opts or {}
  local merged_settings, effect_name = Helpers.process_effect_config(effect, opts)

  M.create_text_animation({
    range = range,
    duration = merged_settings.max_duration or 300,
    from_color = merged_settings.from_color or "Visual",
    to_color = merged_settings.to_color or "Normal",
    effect = effect_name,
    easing = merged_settings.easing,
  })
end

--- Helper: Animate word under cursor
---@param effect string|table Effect name or effect configuration table
---@param opts? table Optional settings override
function M.animate_word(effect, opts)
  if not Helpers.check_enabled() then
    return
  end

  local range = M.get_word_range()
  if not range then
    return
  end

  opts = opts or {}
  local merged_settings, effect_name = Helpers.process_effect_config(effect, opts)

  M.create_text_animation({
    range = range,
    duration = merged_settings.max_duration or 300,
    from_color = merged_settings.from_color or "Visual",
    to_color = merged_settings.to_color or "Normal",
    effect = effect_name,
    easing = merged_settings.easing,
  })
end

--- Helper: Animate current paragraph
---@param effect string|table Effect name or effect configuration table
---@param opts? table Optional settings override
function M.paragraph(effect, opts)
  if not Helpers.check_enabled() then
    return
  end

  opts = opts or {}
  local merged_settings, effect_name = Helpers.process_effect_config(effect, opts)

  M.create_line_animation({
    range = M.get_paragraph_range(),
    duration = merged_settings.max_duration or 300,
    from_color = merged_settings.from_color or "Visual",
    to_color = merged_settings.to_color or "Normal",
    effect = effect_name,
    easing = merged_settings.easing,
  })
end

--- Helper: Animate a specific range with an effect
---@param effect string|table Effect name or effect configuration table
---@param range AnimationRange The range to animate
---@param opts? table Optional settings override
function M.animate_range(effect, range, opts)
  if not Helpers.check_enabled() then
    return
  end

  opts = opts or {}
  local merged_settings, effect_name = Helpers.process_effect_config(effect, opts)
  
  -- Handle -1 for end_col (means end of line)
  local processed_range = vim.deepcopy(range)
  if processed_range.end_col == -1 then
    local buf = vim.api.nvim_get_current_buf()
    local line = vim.api.nvim_buf_get_lines(buf, processed_range.end_line, processed_range.end_line + 1, false)[1]
    if line then
      processed_range.end_col = #line
    else
      processed_range.end_col = 0
    end
  end

  M.create_text_animation({
    range = processed_range,
    duration = merged_settings.max_duration or 300,
    from_color = merged_settings.from_color or "Visual",
    to_color = merged_settings.to_color or "Normal",
    effect = effect_name,
    easing = merged_settings.easing,
  })
end

--- Helper: Create a named animation for a range
---@param name string Animation name
---@param effect string|table Effect name or effect configuration table
---@param range AnimationRange The range to animate
---@param opts? table Optional settings override
function M.named_animate_range(name, effect, range, opts)
  if not Helpers.check_enabled() then
    return
  end

  opts = opts or {}
  local merged_settings, effect_name = Helpers.process_effect_config(effect, opts)

  M.create_named_animation(name, {
    range = range,
    duration = merged_settings.max_duration or 300,
    from_color = merged_settings.from_color or "Visual",
    to_color = merged_settings.to_color or "Normal",
    effect = effect_name,
    easing = merged_settings.easing,
    on_complete = opts.on_complete,
    loop = opts.loop,
    loop_count = opts.loop_count,
  })
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

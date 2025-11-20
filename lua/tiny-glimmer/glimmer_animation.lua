---@class GlimmerAnimation
---@field effect Effect Animation effect implementation
---@field ranges { start_line: number, start_col: number, end_line: number, end_col: number }[] Selection coordinates (supports multiple ranges)
---@field start_time number Unix timestamp when animation started
---@field active boolean Current animation state
---@field id number Animation ID
---@field co thread Lua coroutine
---@field overwrite_from_color string|nil Overwrite from color
---@field overwrite_to_color string|nil Overwrite to color
---@field reserved_ids table Reserved namespace IDs
---@field index_reserved_ids number Index of the reserved namespace IDs
---@field buffer number Buffer ID for the animation
---@field default_effect_settings table Cached copy of effect settings
---@field loop boolean Whether the animation should loop
---@field loop_count number Number of times to loop (0 = infinite)

---@class GlimmerAnimationOpts
---@field range { start_line: number, start_col: number, end_line: number, end_col: number }|nil Single range (deprecated, use ranges)
---@field ranges { start_line: number, start_col: number, end_line: number, end_col: number }[]|nil Multiple ranges
---@field overwrite_from_color string|nil Overwrite from color
---@field overwrite_to_color string|nil Overwrite to color
---@field loop boolean|nil Whether the animation should loop
---@field loop_count number|nil Number of times to loop (0 = infinite)

local GlimmerAnimation = {}
GlimmerAnimation.__index = GlimmerAnimation

local namespace = require("tiny-glimmer.namespace").tiny_glimmer_animation_ns
local namespace_id_pool = require("tiny-glimmer.namespace_id_pool")
local api = vim.api

local HL_GROUP_PREFIX = "TinyGlimmerAnimationHighlight_"
local OVERWRITE_HL_GROUP_PREFIX = "TinyGlimmerAnimationOverwriteHighlight_"

local animation_pool_id = 0

---Creates a new animation effect instance
---@param effect Effect The animation effect implementation to use
---@return GlimmerAnimation The created animation instance
function GlimmerAnimation.new(effect, opts)
  -- Support both single range and multiple ranges
  if not opts.range and not opts.ranges then
    error("TinyGlimmer: range or ranges is required in opts")
  end

  local self = setmetatable({}, GlimmerAnimation)

  self.effect = effect
  self.effect:build_starter()

  self.default_effect_settings = vim.deepcopy(effect.settings)

  -- Convert single range to ranges array for uniform handling
  if opts.ranges then
    self.ranges = opts.ranges
    -- For backwards compatibility, set range to first range
    self.range = opts.ranges[1]
  elseif opts.range then
    self.ranges = { opts.range }
    self.range = opts.range
  end

  self.start_time = 0
  self.active = false

  self.id = animation_pool_id
  self.co = nil

  self.overwrite_from_color = opts.overwrite_from_color
  self.overwrite_to_color = opts.overwrite_to_color

  self.loop = opts.loop or false
  self.loop_count = opts.loop_count or 0

  self.reserved_ids = {}
  self.index_reserved_ids = 1

  self.buffer = api.nvim_get_current_buf()

  animation_pool_id = animation_pool_id + 1

  return self
end

---Computes animation duration based on content length
---@param length number Characters length of the animation
---@param settings { min_duration: number, max_duration: number, chars_for_max_duration: number } Duration configuration
---@return number duration Duration in milliseconds
local function calculate_duration(length, settings)
  -- Fast path for common cases
  if length <= 0 then
    return settings.min_duration
  end

  local max_duration = settings.max_duration
  local chars_for_max = settings.chars_for_max_duration

  if length >= chars_for_max then
    return max_duration
  end

  local calculated_duration = length * max_duration / chars_for_max

  if calculated_duration < settings.min_duration then
    return settings.min_duration
  end

  return calculated_duration
end

---Cleans up the animation effect
function GlimmerAnimation:cleanup()
  self.active = false
  local buffer = self.buffer
  local ids = self.reserved_ids

  for i = 1, #ids do
    api.nvim_buf_del_extmark(buffer, namespace, ids[i])
  end

  -- Clear namespace for all ranges
  for _, range in ipairs(self.ranges) do
    api.nvim_buf_clear_namespace(buffer, namespace, range.start_line, range.end_line + 1)
  end

  animation_pool_id = math.max(0, animation_pool_id - 1)
end

---Updates the animation effect based on progress
---@param progress number Progress of the animation (0 to 1)
---@return number updated_animation_progress Updated progress of the animation
function GlimmerAnimation:update_effect(progress)
  local effect = self.effect
  local easing = effect.settings.easing
  local id = self.id
  local hl_group = HL_GROUP_PREFIX .. id

  local updated_color, updated_animation_progress = effect:update_fn(progress, easing)

  api.nvim_set_hl(0, hl_group, { bg = updated_color })

  -- Handle overwrite colors if specified
  if self.overwrite_from_color or self.overwrite_to_color then
    local overwrite_hl_group = OVERWRITE_HL_GROUP_PREFIX .. id
    local default_settings = self.default_effect_settings

    effect.settings.from_color = self.overwrite_from_color or default_settings.from_color
    effect.settings.to_color = self.overwrite_to_color or default_settings.to_color

    local updated_color_overwrite = effect:update_fn(progress, easing)
    api.nvim_set_hl(0, overwrite_hl_group, { bg = updated_color_overwrite })

    -- Restore original colors
    effect.settings.from_color = default_settings.from_color
    effect.settings.to_color = default_settings.to_color
  end

  return updated_animation_progress
end

---Gets the highlight group for the animation
---@return string Highlight group name
function GlimmerAnimation:get_hl_group()
  return HL_GROUP_PREFIX .. self.id
end

---Gets the overwrite highlight group for the animation
---@return string Overwrite highlight group name
function GlimmerAnimation:get_overwrite_hl_group()
  return OVERWRITE_HL_GROUP_PREFIX .. self.id
end

---Stops the animation
function GlimmerAnimation:stop()
  self.active = false
  self:cleanup()
end

--- Gets the total reserved namespace IDs
--- @return table The reserved namespace IDs
function GlimmerAnimation:get_reserved_ids()
  return self.reserved_ids
end

--- Gets a reserved namespace ID from the pool
--- @return number The reserved namespace ID
function GlimmerAnimation:get_reserved_id()
  local index = self.index_reserved_ids
  local id = self.reserved_ids[index]

  self.index_reserved_ids = index % #self.reserved_ids + 1
  return id
end

-- Create a timer function that returns milliseconds since epoch
local function get_time_ms()
  return vim.uv.now()
end

---Starts the animation
---@param refresh_interval_ms number Refresh interval in milliseconds
---@param length number Length of the content to animate
---@param callbacks { on_update: function, on_complete?: function } Callbacks for animation events
function GlimmerAnimation:start(refresh_interval_ms, length, callbacks)
  self.active = true
  self.start_time = get_time_ms()

  -- Calculate total lines across all ranges
  local lines_count = 0
  for _, range in ipairs(self.ranges) do
    lines_count = lines_count + (range.end_line - range.start_line + 1)
  end
  self.reserved_ids = namespace_id_pool.reserve_ns_ids(lines_count)

  local duration = calculate_duration(length, self.effect.settings)
  local lingering_time = self.effect.settings.lingering_time or 0
  local on_update = callbacks.on_update
  local on_complete = callbacks.on_complete

  self.co = coroutine.create(function()
    local defer_fn = vim.defer_fn
    local current_loop = 0

    while self.active do
      local elapsed_time = get_time_ms() - self.start_time

      -- Calculate progress (clamped between 0 and 1)
      local progress = math.min(elapsed_time / duration, 1)
      local updated_animation_progress = self:update_effect(progress)

      on_update(updated_animation_progress)

      -- Check if animation is complete
      if progress >= 1 then
        -- Handle looping
        if self.loop then
          current_loop = current_loop + 1
          -- loop_count = 0 means infinite, otherwise check if we've looped enough
          if self.loop_count == 0 or current_loop < self.loop_count then
            -- Reset animation start time for next loop
            self.start_time = get_time_ms()
            defer_fn(function()
              coroutine.resume(self.co)
            end, refresh_interval_ms)
            coroutine.yield()
          else
            -- Finished all loops
            if lingering_time > 0 then
              defer_fn(function()
                self:stop()
                if on_complete then
                  on_complete()
                end
              end, lingering_time)
              break
            else
              self:stop()
              if on_complete then
                on_complete()
              end
              break
            end
          end
        else
          -- Not looping, finish normally
          if lingering_time > 0 then
            defer_fn(function()
              self:stop()
              if on_complete then
                on_complete()
              end
            end, lingering_time)
            break
          else
            self:stop()
            if on_complete then
              on_complete()
            end
            break
          end
        end
      else
        -- Schedule next frame
        defer_fn(function()
          coroutine.resume(self.co)
        end, refresh_interval_ms)

        coroutine.yield()
      end
    end
  end)

  coroutine.resume(self.co)
end

return GlimmerAnimation

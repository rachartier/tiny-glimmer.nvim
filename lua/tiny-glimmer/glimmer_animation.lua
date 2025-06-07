---@class GlimmerAnimation
---@field effect Effect Animation effect implementation
---@field range { start_line: number, start_col: number, end_line: number, end_col: number } Selection coordinates
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

---@class GlimmerAnimationOpts
---@field range { start_line: number, start_col: number, end_line: number, end_col: number } Selection coordinates
---@field overwrite_from_color string|nil Overwrite from color
---@field overwrite_to_color string|nil Overwrite to color

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
	if not opts.range then
		error("TinyGlimmer: range is required in opts")
	end

	local self = setmetatable({}, GlimmerAnimation)

	self.effect = effect
	self.effect:build_starter()

	self.default_effect_settings = vim.deepcopy(effect.settings)

	self.range = opts.range
	self.start_time = 0
	self.active = false

	self.id = animation_pool_id
	self.co = nil

	self.overwrite_from_color = opts.overwrite_from_color
	self.overwrite_to_color = opts.overwrite_to_color

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

	api.nvim_buf_clear_namespace(buffer, namespace, self.range.start_line, self.range.end_line + 1)

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

	-- Pre-calculate range size and reserve IDs in one operation
	local lines_count = self.range.end_line - self.range.start_line + 1
	self.reserved_ids = namespace_id_pool.reserve_ns_ids(lines_count)

	local duration = calculate_duration(length, self.effect.settings)
	local lingering_time = self.effect.settings.lingering_time or 0
	local on_update = callbacks.on_update
	local on_complete = callbacks.on_complete

	self.co = coroutine.create(function()
		local defer_fn = vim.defer_fn

		while self.active do
			local elapsed_time = get_time_ms() - self.start_time

			-- Calculate progress (clamped between 0 and 1)
			local progress = math.min(elapsed_time / duration, 1)
			local updated_animation_progress = self:update_effect(progress)

			on_update(updated_animation_progress)

			-- Check if animation is complete
			if progress >= 1 then
				if lingering_time > 0 then
					defer_fn(function()
						self:stop()
						if on_complete then
							on_complete()
						end
					end, lingering_time)
				else
					self:stop()
					if on_complete then
						on_complete()
					end
				end
				break
			end

			-- Schedule next frame
			defer_fn(function()
				coroutine.resume(self.co)
			end, refresh_interval_ms)

			coroutine.yield()
		end
	end)

	coroutine.resume(self.co)
end

return GlimmerAnimation

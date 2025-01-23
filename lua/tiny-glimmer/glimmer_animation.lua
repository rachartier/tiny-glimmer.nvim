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

---@class GlimmerAnimationOpts
---@field range { start_line: number, start_col: number, end_line: number, end_col: number } Selection coordinates
---@field overwrite_from_color string|nil Overwrite from color
---@field overwrite_to_color string|nil Overwrite to color

local GlimmerAnimation = {}
GlimmerAnimation.__index = GlimmerAnimation

local namespace = require("tiny-glimmer.namespace").tiny_glimmer_animation_ns
local namespace_id_pool = require("tiny-glimmer.namespace_id_pool")

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

	self.buffer = vim.api.nvim_get_current_buf()

	animation_pool_id = animation_pool_id + 1

	return self
end

---Computes animation duration based on content length
---@param length number Characters length of the animation
---@param settings { min_duration: number, max_duration: number, chars_for_max_duration: number } Duration configuration
---@return number duration Duration in milliseconds
local function calculate_duration(length, settings)
	local calculated_duration = length * settings.max_duration / settings.chars_for_max_duration

	if calculated_duration < settings.min_duration then
		return settings.min_duration
	end

	return math.min(calculated_duration, settings.max_duration)
end

---Cleans up the animation effect
function GlimmerAnimation:cleanup()
	self.active = false

	for _, id in ipairs(self.reserved_ids) do
		vim.api.nvim_buf_del_extmark(self.buffer, namespace, id)
	end

	animation_pool_id = animation_pool_id - 1
	if animation_pool_id < 0 then
		animation_pool_id = 0
	end
end

---Updates the animation effect based on progress
---@param progress number Progress of the animation (0 to 1)
---@return number updated_animation_progress Updated progress of the animation
function GlimmerAnimation:update_effect(progress)
	local easing = self.effect.settings.easing or nil

	local updated_color, updated_animation_progress = self.effect:update_fn(progress, easing)

	vim.api.nvim_set_hl(0, "TinyGlimmerAnimationHighlight_" .. self.id, { bg = updated_color })

	-- TODO: there must be a better way to handle this
	if self.overwrite_from_color or self.overwrite_to_color then
		self.effect.settings.from_color = self.overwrite_from_color or self.default_effect_settings.from_color
		self.effect.settings.to_color = self.overwrite_to_color or self.default_effect_settings.to_color

		local updated_color_overwrite, _ = self.effect:update_fn(progress, easing)

		vim.api.nvim_set_hl(0, "TinyGlimmerAnimationOverwriteHighlight_" .. self.id, { bg = updated_color_overwrite })

		self.effect.settings.from_color = self.default_effect_settings.from_color
		self.effect.settings.to_color = self.default_effect_settings.to_color
	end

	return updated_animation_progress
end

---Gets the highlight group for the animation
---@return string Highlight group name
function GlimmerAnimation:get_hl_group()
	return "TinyGlimmerAnimationHighlight_" .. self.id
end

---Gets the overwrite highlight group for the animation
---@return string Overwrite highlight group name
function GlimmerAnimation:get_overwrite_hl_group()
	return "TinyGlimmerAnimationOverwriteHighlight_" .. self.id
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
	local id = self.reserved_ids[self.index_reserved_ids]
	self.index_reserved_ids = self.index_reserved_ids + 1

	-- Should not happen, but just in case
	if self.index_reserved_ids > #self.reserved_ids then
		self.index_reserved_ids = 1
	end

	return id
end

---Starts the animation
---@param refresh_interval_ms number Refresh interval in milliseconds
---@param length number Length of the content to animate
---@param callbacks { on_update: function, on_complete?: function } Callbacks for animation events
function GlimmerAnimation:start(refresh_interval_ms, length, callbacks)
	self.active = true
	self.start_time = vim.loop.now()
	self.reserved_ids = namespace_id_pool.reserve_ns_ids(self.range.end_line - self.range.start_line)

	self.co = coroutine.create(function()
		while self.active do
			local current_time = vim.loop.hrtime() / 1e6
			local elapsed_time = current_time - self.start_time
			local duration = calculate_duration(length, self.effect.settings)

			local progress = math.min(elapsed_time / duration, 1)
			local updated_animation_progress = self:update_effect(progress)

			callbacks.on_update(updated_animation_progress)

			if progress >= 1 then
				vim.defer_fn(function()
					self:cleanup()
					if callbacks.on_complete then
						callbacks.on_complete()
					end
				end, self.effect.settings.lingering_time or 0)
				break
			end

			vim.defer_fn(function()
				coroutine.resume(self.co)
			end, refresh_interval_ms)

			coroutine.yield()
		end
	end)

	coroutine.resume(self.co)
end

return GlimmerAnimation

---@class AnimationEffect
---@field effect Effect Animation effect implementation
---@field range { start_line: number, start_col: number, end_line: number, end_col: number } Selection coordinates
---@field start_time number Unix timestamp when animation started
---@field active boolean Current animation state
---@field content string[] Lines of text being animated
---@field yank_type string Vim's register type (v, V, or ^V)
---@field operation string Vim operator that triggered animation (y, d, c)
---@field visual_highlight table Visual selection highlight attributes
---@field id number Unique identifier for this animation instance
---@field cursor_line_enabled boolean Whether to show special cursor line animation
---@field cursor_line_color string|nil Hex color code for cursor line highlight
---@field virtual_text_priority number Priority level for virtual text rendering
local AnimationEffect = {}
AnimationEffect.__index = AnimationEffect

local tiny_glimmer_ns = vim.api.nvim_create_namespace("tiny-glimmer")

local utils = require("tiny-glimmer.utils")

local animation_pool_id = 0

---Creates a new animation effect instance
---@param effect Effect The animation effect implementation to use
---@param opts { range: table, content: string|string[], virtual_text_priority?: number } Configuration options
---@return AnimationEffect|nil effect The created animation instance
---@return string? error Error message if creation failed
function AnimationEffect.new(effect, opts)
	if not opts.range then
		return nil, "Selection is required"
	end

	local self = setmetatable({}, AnimationEffect)

	self.effect = effect
	self.range = opts.range
	self.start_time = vim.loop.now()
	self.active = true

	if type(opts.content) == "string" then
		self.content = { opts.content }
	else
		self.content = opts.content
	end

	self.yank_type = vim.v.event.regtype or "v"
	self.operation = vim.v.event.operator or "y"

	self.visual_highlight = utils.get_highlight("Visual")
	self.virtual_text_priority = opts.virtual_text_priority or 128

	self.id = animation_pool_id
	animation_pool_id = animation_pool_id + 1

	local cursor_line_hl = utils.get_highlight("CursorLine").bg

	self.cursor_line_enabled = false
	self.cursor_line_color = nil

	if cursor_line_hl ~= nil and cursor_line_hl ~= "None" then
		self.cursor_line_enabled = true
		self.cursor_line_color = utils.int_to_hex(cursor_line_hl)
	end

	return self
end

---Computes animation duration based on content length
---@param content string[] Text content to animate
---@param settings { min_duration: number, max_duration: number, chars_for_max_duration: number } Duration configuration
---@return number duration Duration in milliseconds
local function calculate_duration(content, settings)
	if #content ~= 1 then
		return settings.max_duration
	end

	local calculated_duration = #content[1] * settings.max_duration / settings.chars_for_max_duration

	if calculated_duration < settings.min_duration then
		return settings.min_duration
	end

	return math.min(calculated_duration, settings.max_duration)
end

---Computes line configurations for the animation
---@param self AnimationEffect Animation instance
---@param animation_progress number Current progress (0 to 1)
---@return { line_number: number, start_position: number, end_position: number }[] Line configurations

local function compute_lines_range(self, animation_progress)
	local lines = {}
	local is_Visual = string.byte(self.yank_type) == 22
	local is_visual = self.yank_type == "v"
	local start_position = self.range.start_col

	if self.content ~= nil then
		for i, line_content in ipairs(self.content) do
			local end_position = #line_content * animation_progress

			if is_visual then
				if i == 1 or i == #self.content then
					end_position = self.range.end_col * animation_progress
				end
			elseif is_Visual then
				-- FIXME: When there is tabs in the line
				-- and multiple lines
				-- the extmakr is not correctly placed, offset is wrong
			end

			table.insert(lines, {
				line_number = i - 1,
				start_position = (i == 1 or is_Visual) and start_position or 0,
				end_position = end_position,
			})
		end
	end
	return lines
end

---Renders one line of the animation effect
---@param self AnimationEffect Animation instance
---@param line { line_number: number, start_position: number, end_position: number } Line configuration
local function apply_hl(self, line)
	local line_index = line.line_number + self.range.start_line

	local hl_group = "TinyGlimmerAnimationHighlight_" .. self.id
	if self.cursor_line_enabled then
		local cursor_position = vim.api.nvim_win_get_cursor(0)

		if cursor_position[1] - 1 == line_index then
			hl_group = "TinyGlimmerAnimationCursorLineHighlight_" .. self.id
		end
	end

	utils.set_extmark(line_index, tiny_glimmer_ns, line.start_position, {
		end_col = line.end_position,
		hl_group = hl_group,
		hl_mode = "blend",
		priority = self.virtual_text_priority,
	})
end

function AnimationEffect:cleanup()
	self.active = false
	vim.defer_fn(function()
		vim.api.nvim_buf_clear_namespace(0, tiny_glimmer_ns, 0, -1)
	end, self.effect.settings.lingering_time or 0)

	animation_pool_id = animation_pool_id - 1
	if animation_pool_id < 0 then
		animation_pool_id = 0
	end
end

function AnimationEffect:update_effect(progress)
	local easing = self.effect.settings.easing or nil

	local updated_color, updated_animation_progress = self.effect:update_fn(progress, easing)

	vim.api.nvim_set_hl(0, "TinyGlimmerAnimationHighlight_" .. self.id, { bg = updated_color })

	if self.cursor_line_enabled then
		local updated_color_cursor_line, _ =
			self.effect(self, self.settings.from_color, self.cursor_line_color, progress, easing)

		vim.api.nvim_set_hl(
			0,
			"TinyGlimmerAnimationCursorLineHighlight_" .. self.id,
			{ bg = updated_color_cursor_line }
		)
	end

	return updated_animation_progress
end

---Updates animation state and schedules next frame
---@param refresh_interval_ms number Milliseconds between animation frames
---@return boolean? completed Returns true when animation is finished
function AnimationEffect:update(refresh_interval_ms)
	if not self.active then
		return
	end

	local current_time = vim.loop.now()
	local elapsed_time = current_time - self.start_time
	local duration = calculate_duration(self.content, self.effect.settings)
	local progress = math.min(elapsed_time / duration, 1)

	local updated_animation_progress = self:update_effect(progress)

	vim.api.nvim_buf_clear_namespace(0, tiny_glimmer_ns, self.range.start_line, self.range.end_line + 1)

	local lines_range = compute_lines_range(self, updated_animation_progress)
	for _, line_range in ipairs(lines_range) do
		apply_hl(self, line_range)
	end

	if progress >= 1 then
		self:cleanup()
		return true
	else
		vim.defer_fn(function()
			self:update(refresh_interval_ms)
		end, refresh_interval_ms)
	end
end

return AnimationEffect

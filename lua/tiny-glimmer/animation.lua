---@class AnimationEffect
---@field type string The type of animation effect
---@field settings table Animation settings and configuration
---@field selection table Selection coordinates {start_line, start_col, end_line, end_col}
---@field start_time number Animation start timestamp
---@field active boolean Whether the animation is currently active
---@field content table[] Array of yanked content lines
---@field yank_type string Type of yank operation
---@field operation string Operator used for the operation
---@field visual_highlight table Visual mode highlight settings
---@field id number Animation effect identifier
---@field cursor_line_enabled boolean Whether the cursor line is enabled
---@field cursor_line_color string Cursor line color
---@field effect function Animation effect function
---@field virt_text_settings table Virtual text configuration
local AnimationEffect = {}
AnimationEffect.__index = AnimationEffect

local tiny_glimmer_ns = vim.api.nvim_create_namespace("tiny-glimmer")

local utils = require("tiny-glimmer.utils")
local animation_effects = require("tiny-glimmer.effects")

---Validate animation settings
---@param animation_type string
---@param animation_settings table
---@return boolean, string?
local function validate_settings(animation_type, animation_settings)
	if not animation_effects[animation_type] and not animation_type == "custom" then
		return false, string.format("Invalid animation type: %s", animation_type)
	end

	local required_fields = { "min_duration", "max_duration", "chars_for_max_duration" }
	for _, field in ipairs(required_fields) do
		if not animation_settings[field] then
			return false, string.format("Missing required setting: %s", field)
		end
	end

	return true
end

local animation_pool_id = 0

---Creates a new animation effect instance
---@param animation_type string Type of animation to apply
---@param animation_settings table Configuration for the animation
---@param selection table Selection coordinates
---@param content string[] Array of yanked content lines
---@return AnimationEffect|nil effect The created animation effect
---@return string? error Error message if creation failed
function AnimationEffect.new(animation_type, animation_settings, selection, content)
	-- Validate inputs
	local is_valid, error_msg = validate_settings(animation_type, animation_settings)
	if not is_valid then
		return nil, error_msg
	end

	local self = setmetatable({}, AnimationEffect)

	self.type = animation_type
	self.settings = animation_settings
	self.selection = selection
	self.start_time = vim.loop.now()
	self.active = true

	if type(content) == "string" then
		content = { content }
	end

	self.content = content
	self.yank_type = vim.v.event.regtype or "v"
	self.operation = vim.v.event.operator or "y"

	self.visual_highlight = utils.get_highlight("Visual")
	self.virt_text_settings = animation_settings.virt_text or {}

	self.id = animation_pool_id
	animation_pool_id = animation_pool_id + 1

	local cursor_line_hl = utils.get_highlight("CursorLine").bg

	self.cursor_line_enabled = false
	self.cursor_line_color = nil

	if cursor_line_hl ~= nil and cursor_line_hl ~= "None" then
		self.cursor_line_enabled = true
		self.cursor_line_color = utils.int_to_hex(cursor_line_hl)
	end

	if self.type == "custom" then
		self.effect = self.settings.effect
	else
		self.effect = animation_effects[self.type]
	end

	return self
end

---Calculate animation duration based on content length
---@param content string[] Yanked content lines
---@param settings table Animation settings
---@return number duration
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
	end, self.settings.lingering_time or 0)

	animation_pool_id = animation_pool_id - 1
	if animation_pool_id < 0 then
		animation_pool_id = 0
	end
end

function AnimationEffect:update_effect(progress)
	local easing = self.settings.easing or nil

	local updated_color, updated_animation_progress =
		self.effect(self, self.settings.from_color, self.settings.to_color, progress, easing)

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

---Update the animation state
---@param refresh_interval_ms number Interval between updates in milliseconds
function AnimationEffect:update(refresh_interval_ms)
	if not self.active then
		return
	end

	local current_time = vim.loop.now()
	local elapsed_time = current_time - self.start_time
	local duration = calculate_duration(self.content, self.settings)
	local progress = math.min(elapsed_time / duration, 1)

	if self.settings.min_progress then
		if progress < self.settings.min_progress then
			progress = self.settings.min_progress
		end
	end

	local updated_animation_progress = self:update_effect(progress)

	vim.api.nvim_buf_clear_namespace(0, tiny_glimmer_ns, self.selection.start_line, self.selection.end_line + 1)

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

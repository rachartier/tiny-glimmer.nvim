---@class TextAnimation
---@field content string[] Lines of text being animated
---@field event_type string Vim's register type (v, V, or ^V)
---@field event Event Event type information
---@field operation string Vim operator that triggered animation (y, d, c)
---@field id number Unique identifier for this animation instance
---@field cursor_line_enabled boolean Whether to show special cursor line animation
---@field cursor_line_color string|nil Hex color code for cursor line highlight
---@field virtual_text_priority number Priority level for virtual text rendering
---@field animation AnimationEffect Animation effect instance

---@class Event
---@field is_visual boolean
---@field is_line boolean
---@field is_visual_block boolean
---@field is_paste boolean

local TextAnimation = {}
TextAnimation.__index = TextAnimation

local utils = require("tiny-glimmer.utils")
local namespace = require("tiny-glimmer.namespace").tiny_glimmer_animation_ns
local AnimationEffect = require("tiny-glimmer.glimmer_animation")

---Creates a new TextAnimation instance
---@param effect any The animation effect implementation to use
---@param opts table Configuration options
---@return TextAnimation The created TextAnimation instance
function TextAnimation.new(effect, opts)
	local self = setmetatable({}, TextAnimation)

	if not opts.base then
		error("opts.base is required")
	end

	if type(opts.content) == "string" then
		self.content = { opts.content }
	else
		self.content = opts.content
	end

	self.virtual_text_priority = opts.virtual_text_priority or 128

	self.event_type = vim.v.event.regtype
	self.event = {
		is_visual = self.event_type == "v",
		is_line = string.byte(self.event_type or "") == 86,
		is_visual_block = string.byte(self.event_type or "") == 22,
		is_paste = opts.is_paste,
	}
	self.operation = vim.v.event.operator

	local cursor_line_hl = utils.get_highlight("CursorLine").bg
	local animation_opts = opts.base

	self.cursor_line_enabled = false

	if cursor_line_hl ~= nil and cursor_line_hl ~= "None" then
		self.cursor_line_enabled = true
		animation_opts = vim.tbl_extend("force", opts.base, {
			overwrite_to_color = utils.int_to_hex(cursor_line_hl),
		})
	end
	self.animation = AnimationEffect.new(effect, animation_opts)

	return self
end

---Computes line configurations for the animation
---@param self TextAnimation Animation instance
---@param animation_progress number Current progress (0 to 1)
---@return table[] Line configurations
local function compute_lines_range(self, animation_progress)
	local lines = {}
	local start_position = self.animation.range.start_col

	if self.content ~= nil then
		for i, line_content in ipairs(self.content) do
			local line_length = #line_content
			local count = 0

			if self.event.is_paste then
				if i == #self.content then
					count = line_length
				else
					count = 999999
				end
			else
				count = math.floor(line_length * animation_progress)
			end

			if self.event.is_visual_block then
				-- FIXME: When there is tabs in the line
				-- and multiple lines
				-- the extmark is not correctly placed, offset is wrong
			end

			table.insert(lines, {
				line_number = i - 1,
				start_position = (i == 1 or self.event.is_visual_block) and start_position or 0,
				count = count,
			})
		end
	end
	return lines
end

---Renders one line of the animation effect
---@param self TextAnimation Animation instance
---@param line table Line configuration
local function apply_hl(self, line)
	local line_index = line.line_number + self.animation.range.start_line

	local hl_group = self.animation:get_hl_group()
	if self.cursor_line_enabled then
		local cursor_position = vim.api.nvim_win_get_cursor(0)

		if cursor_position[1] - 1 == line_index then
			hl_group = self.animation:get_overwrite_hl_group()
		end
	end

	utils.set_extmark(line_index, namespace, line.start_position, {
		virt_text_pos = "overlay",
		end_col = line.start_position + line.count,
		hl_group = hl_group,
		hl_mode = "blend",
		priority = self.virtual_text_priority,
	})
end

---Starts the text animation
---@param refresh_interval_ms number Refresh interval in milliseconds
function TextAnimation:start(refresh_interval_ms)
	self.animation:start(refresh_interval_ms, #self.content[1], function(update_progress)
		vim.api.nvim_buf_clear_namespace(
			0,
			namespace,
			self.animation.range.start_line,
			self.animation.range.end_line + 1
		)

		local lines_range = compute_lines_range(self, update_progress)
		for _, line_range in ipairs(lines_range) do
			apply_hl(self, line_range)
		end
	end)
end

return TextAnimation

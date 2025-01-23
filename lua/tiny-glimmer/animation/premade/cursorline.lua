---@class CursorLineAnimation
---@field cursor_line_enabled boolean Whether to show special cursor line animation
---@field cursor_line_color string|nil Hex color code for cursor line highlight
---@field virtual_text_priority number Priority level for virtual text rendering
---@field animation GlimmerAnimation Animation effect instance

local CursorLineAnimation = {}
CursorLineAnimation.__index = CursorLineAnimation

local utils = require("tiny-glimmer.utils")
local namespace = require("tiny-glimmer.namespace").tiny_glimmer_animation_ns
local namespace_id_pool = require("tiny-glimmer.namespace_id_pool")
local AnimationEffect = require("tiny-glimmer.glimmer_animation")

--- Creates anew LineAnimation Instance
---@param effect any The animiation effect implementation to use
---@param opts table Configuration options
---@return LineAnimation The created LineAnimation instance
function CursorLineAnimation.new(effect, opts)
	local self = setmetatable({}, CursorLineAnimation)

	if not opts.base then
		error("opts.base is required")
	end

	self.virtual_text_priority = opts.virtual_text_priority or 128

	local animation_opts = opts.base

	self.animation = AnimationEffect.new(effect, animation_opts)

	return self
end

function CursorLineAnimation:start(refresh_interval_ms, on_complete)
	self.animation:start(refresh_interval_ms, 1, {
		on_update = function(update_progress)
			vim.api.nvim_buf_clear_namespace(
				0,
				namespace,
				self.animation.range.start_line,
				self.animation.range.start_line + 1
			)

			vim.api.nvim_set_hl(0, "CursorLine", {
				link = self.animation:get_hl_group(),
			})
		end,
		on_complete = function()
			if on_complete then
				on_complete()
			end
		end,
	})
end

function CursorLineAnimation:stop()
	self.animation:stop()
end

return CursorLineAnimation

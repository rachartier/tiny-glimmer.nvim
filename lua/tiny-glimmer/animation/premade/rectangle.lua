local RectangleAnimation = {}
RectangleAnimation.__index = RectangleAnimation

local namespace = require("tiny-glimmer.namespace").tiny_glimmer_animation_ns
local GlimmerAnimation = require("tiny-glimmer.glimmer_animation")
local utils = require("tiny-glimmer.utils")

---Creates a new RectangleAnimation
function RectangleAnimation.new(effect, opts)
	local self = setmetatable({}, RectangleAnimation)

	if not opts.base then
		error("opts.base is required")
	end

	self.animation = GlimmerAnimation.new(effect, opts.base)

	return self
end

function RectangleAnimation:start(refresh_interval_ms)
	local length = self.animation.range.end_col - self.animation.range.start_col

	self.animation:start(refresh_interval_ms, length, function(update_progress)
		local hl_group = self.animation:get_hl_group()

		for i = self.animation.range.start_line, self.animation.range.end_line do
			vim.api.nvim_buf_set_extmark(0, namespace, i, self.animation.range.start_col, {
				virt_text = { { string.rep(" ", length), hl_group } },
				hl_group = hl_group,
				hl_mode = "blend",
				virt_text_pos = "overlay",
			})
		end
	end)
end

return RectangleAnimation

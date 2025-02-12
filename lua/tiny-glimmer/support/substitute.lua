local M = {}

local utils = require("tiny-glimmer.utils")
local settings = nil

function M.setup(opts)
	settings = opts
end

function M.substitute_cb(param)
	if settings == nil then
		return
	end

	vim.schedule(function()
		local range = utils.get_range_yank()

		require("tiny-glimmer.animation.factory").get_instance():create_text_animation(settings.default_animation, {
			base = {
				range = range,
			},
			is_paste = true,
		})
	end)
end

return M

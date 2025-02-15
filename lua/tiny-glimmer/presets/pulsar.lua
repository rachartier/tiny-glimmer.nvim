local M = {}

local animation_group = require("tiny-glimmer.namespace").animation_group
local AnimationFactory = require("tiny-glimmer.animation.factory")

function M.setup(opts)
	vim.api.nvim_create_autocmd(opts.on_event, {
		group = animation_group,
		callback = function()
			vim.schedule(function()
				local pos = vim.api.nvim_win_get_cursor(0)

				AnimationFactory.get_instance():create_line_animation(opts.default_animation, {
					base = {
						range = {
							start_line = pos[1] - 1,
							start_col = 0,
							end_line = pos[1],
							end_col = 0,
						},
					},
				})
			end)
		end,
	})
end

return M

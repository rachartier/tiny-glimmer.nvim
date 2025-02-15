local M = {}

local animation_group = require("tiny-glimmer.namespace").animation_group
local AnimationFactory = require("tiny-glimmer.animation.factory")
local utils = require("tiny-glimmer.utils")

function M.setup(opts)
	vim.api.nvim_create_autocmd("TextYankPost", {
		group = animation_group,
		callback = function()
			if vim.v.event.operator == "d" or vim.v.event.operator == "c" then
				return
			end

			local range = utils.get_range_yank()

			AnimationFactory.get_instance():create_text_animation(opts.default_animation, {
				base = {
					range = range,
				},
			})
		end,
	})
end

return M

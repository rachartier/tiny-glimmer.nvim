local M = {}

local utils = require("tiny-glimmer.utils")
local settings = {}

local function split_lines(text)
	local lines = {}

	for i = 0, vim.v.count1 - 1 do
		for line in text:gmatch("[^\r\n]+") do
			table.insert(lines, line)
		end
	end

	return lines
end

function M.setup(opts)
	settings = opts
end

function M.substitute_cb(param)
	if settings == nil then
		return
	end

	local register = param.register
	local text = split_lines(vim.fn.getreg(register, true))

	vim.schedule(function()
		local range = utils.get_range_yank()

		require("tiny-glimmer.animation.factory").get_instance():create_text_animation(settings.default_animation, {
			base = {
				range = range,
			},
			is_paste = true,
			content = text,
		})
	end)
end

return M

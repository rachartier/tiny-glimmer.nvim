local M = {}
local utils = require("tiny-glimmer.utils")

local function split_lines(text)
	local lines = {}

	for i = 0, vim.v.count1 - 1 do
		for line in text:gmatch("[^\r\n]+") do
			table.insert(lines, line)
		end
	end

	return lines
end

local function animate_paste(opts, mode)
	local register = vim.v.register or '"'
	local text = split_lines(vim.fn.getreg(register, true))

	vim.schedule(function()
		local range = utils.get_range_yank()

		require("tiny-glimmer.animation.factory").get_instance():create_text_animation(opts.default_animation, {
			base = {
				range = range,
			},
			is_paste = true,
			content = text,
		})
	end)
end

function M.paste(opts)
	animate_paste(opts, "p")
end

function M.Paste(opts)
	animate_paste(opts, "P")
end

function M.paste_insert(opts)
	animate_paste(opts, "<C-R>")
end

return M

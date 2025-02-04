local M = {}
local utils = require("tiny-glimmer.utils")

local function get_paste_mode()
	return vim.opt.paste:get()
end

local function restore_paste_mode(previous_state)
	vim.opt.paste = previous_state
end

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
	local paste_mode = get_paste_mode()
	local register = vim.v.register or '"'
	local text = split_lines(vim.fn.getreg(register, true))

	local cmd = mode

	if mode == "p" then
		if type(opts.paste_mapping) == "function" then
			cmd = opts.paste_mapping()
		else
			cmd = opts.paste_mapping
		end
	elseif mode == "P" then
		if type(opts.Paste_mapping) == "function" then
			cmd = opts.Paste_mapping()
		else
			cmd = opts.Paste_mapping
		end
	end

	local prefix = register ~= '"' and '"' .. register or ""
	local keys = vim.api.nvim_replace_termcodes(prefix .. vim.v.count1 .. cmd, true, true, true)
	vim.api.nvim_feedkeys(keys, "n", false)
	restore_paste_mode(paste_mode)

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

return M

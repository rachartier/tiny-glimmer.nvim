local M = {}

local function get_paste_mode()
	return vim.opt.paste:get()
end

local function restore_paste_mode(previous_state)
	vim.opt.paste = previous_state
end

local function split_lines(text)
	local lines = {}
	for line in text:gmatch("[^\r\n]+") do
		line = line:gsub("\t", string.rep(" ", vim.bo.tabstop))
		table.insert(lines, line)
	end
	return lines
end

local function animate_paste(opts, mode)
	local paste_mode = get_paste_mode()
	local text = split_lines(vim.fn.getreg('"', true))

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

	vim.fn.feedkeys(vim.v.count1 .. cmd, "n")
	restore_paste_mode(paste_mode)

	vim.schedule(function()
		local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(0, "["))
		local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(0, "]"))

		local selection = {
			start_line = start_row - 1,
			start_col = start_col,
			end_line = end_row - 1,
			end_col = end_col,
		}

		require("tiny-glimmer.animation_factory").get_instance():create(opts.default_animation, selection, text)
	end)
end

function M.paste(opts)
	animate_paste(opts, "p")
end

function M.Paste(opts)
	animate_paste(opts, "P")
end

return M

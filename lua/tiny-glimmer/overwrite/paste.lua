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
		table.insert(lines, line)
	end
	return lines
end

local function animate_paste(opts, mode)
	local paste_mode = get_paste_mode()
	local text = split_lines(vim.fn.getreg('"', true))

	local cmd = mode

	if mode == "p" and opts.paste_mapping ~= nil then
		cmd = cmd .. opts.paste_mapping
	elseif mode == "P" and opts.Paste_mapping ~= nil then
		cmd = cmd .. opts.Paste_mapping
	end

	vim.fn.feedkeys(cmd, "n")
	restore_paste_mode(paste_mode)

	vim.schedule(function()
		local selection = {
			start_line = vim.fn.line("'[") - 1,
			start_col = vim.fn.col("'[") - 1,
			end_line = vim.fn.line("']") - 1,
			end_col = vim.fn.col("']"),
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

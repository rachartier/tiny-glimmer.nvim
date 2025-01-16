local M = {}

local function search(opts, direction, search_pattern)
	local buf = vim.api.nvim_get_current_buf()
	vim.fn.search(search_pattern, direction)

	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local matches = vim.fn.matchbufline(buf, search_pattern, cursor_pos[1], cursor_pos[1])

	if vim.tbl_isempty(matches) then
		return
	end

	local keys = direction == "w" and opts.next_mapping or opts.prev_mapping
	if keys ~= nil and keys ~= "" then
		vim.fn.feedkeys(direction == "w" and opts.next_mapping or opts.prev_mapping)
	end

	local selection = {
		start_line = cursor_pos[1] - 1,
		start_col = cursor_pos[2],
		end_line = cursor_pos[1] - 1,
		end_col = cursor_pos[2] + #matches[1].text,
	}

	require("tiny-glimmer.animation_factory").get_instance():create(opts.default_animation, selection, matches[1].text)
end

function M.search_on_line(opts)
	search(opts, "n", vim.fn.getreg("/"))
end

function M.search_next(opts)
	search(opts, "w", vim.fn.getreg("/"))
end

function M.search_prev(opts)
	search(opts, "bw", vim.fn.getreg("/"))
end

function M.search_under_cursor(opts)
	local word_under_cursor = vim.fn.expand("<cword>")
	search(opts, "w", word_under_cursor)
end

return M

local M = {}

local function search(opts, keys, search_pattern)
	local buf = vim.api.nvim_get_current_buf()

	if keys ~= nil then
		vim.fn.feedkeys(vim.v.count1 .. keys, "n")
	end

	vim.schedule(function()
		local cursor_pos = vim.api.nvim_win_get_cursor(0)
		local matches = vim.fn.matchbufline(buf, search_pattern, cursor_pos[1], cursor_pos[1])

		if vim.tbl_isempty(matches) then
			return
		end

		local range = {
			start_line = cursor_pos[1] - 1,
			start_col = cursor_pos[2],
			end_line = cursor_pos[1] - 1,
			end_col = cursor_pos[2] + #matches[1].text,
		}

		require("tiny-glimmer.animation.factory").get_instance():create_text_animation(opts.default_animation, {
			base = {
				range = range,
			},
		})
	end)
end

function M.search_on_line(opts)
	search(opts, nil, vim.fn.getreg("/"))
end

function M.search_next(opts)
	local keys

	if type(opts.next_mapping) == "function" then
		keys = opts.next_mapping()
	else
		keys = opts.next_mapping
	end

	search(opts, keys, vim.fn.getreg("/"))
end

function M.search_prev(opts)
	local keys

	if type(opts.prev_mapping) == "function" then
		keys = opts.prev_mapping()
	else
		keys = opts.prev_mapping
	end

	search(opts, keys, vim.fn.getreg("/"))
end

function M.search_under_cursor(opts)
	local word_under_cursor = vim.fn.expand("<cword>")
	search(opts, "*", word_under_cursor)
end

return M

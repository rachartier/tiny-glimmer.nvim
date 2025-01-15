local M = {}

local AnimationEffect = require("tiny-glimmer.animation")

local function search(opts, direction, animations, animation_refresh)
	local search_pattern = vim.fn.getreg("/")
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

	local animation, error_msg =
		AnimationEffect.new(opts.default_animation, animations[opts.default_animation], selection, matches[1].text)

	if animation then
		animation:update(animation_refresh)
	else
		vim.notify("TinyGlimmer: " .. error_msg, vim.log.levels.ERROR)
	end
end

function M.search_next(opts, animations, animation_refresh)
	search(opts, "w", animations, animation_refresh)
end

function M.search_prev(opts, animations, animation_refresh)
	search(opts, "bw", animations, animation_refresh)
end

return M

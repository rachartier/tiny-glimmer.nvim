local M = {}

local utils = require("tiny-glimmer.utils")
local AnimationFactory = require("tiny-glimmer.animation.factory")

local function get_mode_color(mode)
	if mode == "v" or mode == "V" or mode == "^V" then
		return "MiniStatuslineModeVisual"
	elseif mode == "i" then
		return "MiniStatuslineModeInsert"
	elseif mode == "R" or mode == "Rv" then
		return "MiniStatuslineModeReplace"
	elseif mode == "c" then
		return "MiniStatuslineModeCommand"
	end

	return "Normal"
end

function M.init(anim)
	local default_cusorline_bg = utils.int_to_hex(utils.get_highlight("CursorLine").bg)

	vim.api.nvim_create_autocmd("ModeChanged", {
		callback = function(event)
			vim.schedule(function()
				local pos = vim.api.nvim_win_get_cursor(0)

				local last_mode = event.match:sub(1, 1)
				local mode = event.match:sub(3)

				local to_color = utils.int_to_hex(utils.get_highlight(get_mode_color(mode)).bg)
				local from_color = utils.int_to_hex(utils.get_highlight(get_mode_color(last_mode)).bg)

				to_color = utils.blend(to_color, default_cusorline_bg, anim.blend)
				from_color = utils.blend(from_color, default_cusorline_bg, anim.blend)

				anim.default_animation.settings.to_color = to_color
				anim.default_animation.settings.from_color = from_color

				AnimationFactory.get_instance():create_cursorline_animation(anim.default_animation, {
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

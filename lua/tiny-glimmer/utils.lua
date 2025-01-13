local M = {}

---Converts an integer to a hex color string
---@param int number|nil The integer to convert
---@return string hex The resulting hex color or "None"
function M.int_to_hex(int)
	if not int then
		return "None"
	end
	return string.format("#%06X", int)
end

--- Get the highlight group
--- @param name string The name of the highlight group
--- @return table The highlight group
function M.get_highlight(name)
	local highlight = vim.api.nvim_get_hl(0, {
		name = name,
		link = false,
	})

	return {
		fg = highlight.fg,
		bg = highlight.bg,
		bold = highlight.bold or false,
		italic = highlight.italic or false,
	}
end

--- Convert a hex color to an RGB table
--- @param hex_color string The hex color to convert
--- @return table The RGB table
function M.hex_to_rgb(hex_color)
	if hex_color == "NONE" then
		return { r = 0, g = 0, b = 0 }
	end
	hex_color = hex_color:gsub("#", "")
	return {
		r = tonumber(hex_color:sub(1, 2), 16),
		g = tonumber(hex_color:sub(3, 4), 16),
		b = tonumber(hex_color:sub(5, 6), 16),
	}
end

--- Convert an RGB table to a hex color
--- @param rgb_color table The RGB table to convert
--- @return string The hex color
function M.rgb_to_hex(rgb_color)
	return string.format("#%02X%02X%02X", rgb_color.r, rgb_color.g, rgb_color.b)
end

return M

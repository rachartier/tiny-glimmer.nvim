local M = {}

local MAX_COLOR_VALUE = 255
local HEX_BASE = 16
M.max_number = 2 ^ 31 - 1

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

function M.get_range_last_modification(buf)
	if buf == nil then
		buf = 0
	end

	local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(buf, "["))
	local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(buf, "]"))

	return {
		start_line = start_row - 1,
		start_col = start_col,
		end_line = end_row - 1,
		end_col = end_col,
	}
end

function M.get_range_yank()
	return {
		start_line = vim.fn.line("'[") - 1,
		start_col = vim.fn.col("'[") - 1,
		end_line = vim.fn.line("']") - 1,
		end_col = vim.fn.col("']"),
	}
end

function M.get_range_line()
	local line = vim.fn.getline(".")

	return {
		start_line = line,
		start_col = 0,
		end_line = line,
		end_col = #line,
	}
end

function M.get_visual_range_yank()
	local start_mark = vim.api.nvim_buf_get_mark(0, "<")
	local end_mark = vim.api.nvim_buf_get_mark(0, ">")

	return {
		start_line = start_mark[1],
		start_col = start_mark[2],
		end_line = end_mark[1],
		end_col = end_mark[2],
	}
end

function M.set_extmark(line, ns_id, col, opts)
	line = math.max(0, line)
	col = math.max(0, col)

	opts = opts or {}
	opts.strict = false

	return vim.api.nvim_buf_set_extmark(0, ns_id, line, col, opts)
end

function M.blend(foreground, background, alpha)
	-- Convert hex alpha to decimal if needed
	if type(alpha) == "string" then
		alpha = tonumber(alpha, HEX_BASE) / 0xff
	end

	-- Validate alpha range
	alpha = math.max(0, math.min(1, alpha or 0))

	local fg = M.hex_to_rgb(foreground)
	local bg = M.hex_to_rgb(background)

	---@param channel string
	---@return number
	local function blend_channel(channel)
		local value = (alpha * fg[channel] + ((1 - alpha) * bg[channel]))
		return math.floor(math.min(math.max(0, value), MAX_COLOR_VALUE) + 0.5)
	end

	return string.format("#%02X%02X%02X", blend_channel("r"), blend_channel("g"), blend_channel("b"))
end

return M

---@class TinyGlimmerRangeUtils
---@field get_cursor_range function Get current cursor position as a range
---@field get_visual_range function Get current visual selection as a range
---@field get_line_range function Get the range for a specific line
---@field get_yank_range function Get the yank range from the last yank operation

local M = {}

---@class AnimationRange
---@field start_line number 0-indexed start line
---@field start_col number 0-indexed start column
---@field end_line number 0-indexed end line
---@field end_col number 0-indexed end column

--- Get current cursor position as a range
---@return AnimationRange
function M.get_cursor_range()
  local pos = vim.api.nvim_win_get_cursor(0)
  return {
    start_line = pos[1] - 1,
    start_col = pos[2],
    end_line = pos[1] - 1,
    end_col = pos[2] + 1,
  }
end

--- Get current visual selection as a range
---@return AnimationRange|nil
function M.get_visual_range()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  if start_pos[2] == 0 or end_pos[2] == 0 then
    return nil
  end

  return {
    start_line = start_pos[2] - 1,
    start_col = start_pos[3] - 1,
    end_line = end_pos[2] - 1,
    end_col = end_pos[3],
  }
end

--- Get the range for a specific line
---@param line number 1-indexed line number (0 for current line)
---@return AnimationRange
function M.get_line_range(line)
  line = line or 0
  if line == 0 then
    line = vim.api.nvim_win_get_cursor(0)[1]
  end

  local buffer = vim.api.nvim_get_current_buf()
  local line_content = vim.api.nvim_buf_get_lines(buffer, line - 1, line, false)[1] or ""

  return {
    start_line = line - 1,
    start_col = 0,
    end_line = line - 1,
    end_col = #line_content,
  }
end

--- Get the yank range from the last yank operation
---@return AnimationRange|nil
function M.get_yank_range()
  local start_pos = vim.fn.getpos("'[")
  local end_pos = vim.fn.getpos("']")

  if start_pos[2] == 0 or end_pos[2] == 0 then
    return nil
  end

  return {
    start_line = start_pos[2] - 1,
    start_col = start_pos[3] - 1,
    end_line = end_pos[2] - 1,
    end_col = end_pos[3],
  }
end

return M

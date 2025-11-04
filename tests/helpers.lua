local H = {}

--- Create a buffer with given lines
---@param lines? string[] Lines to set in buffer
---@return integer Buffer handle
function H.make_buf(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or { "" })
  return buf
end

--- Execute function with a temporary buffer
---@param lines? string[] Lines to set in buffer
---@param fn fun(buf: integer): any Function to execute with buffer
---@return any Result of fn
function H.with_buf(lines, fn)
  local buf = H.make_buf(lines)
  local ok, result = pcall(fn, buf)
  vim.api.nvim_buf_delete(buf, { force = true })
  if not ok then
    error(result)
  end
  return result
end

--- Setup a window with buffer and cursor position
---@param buf integer Buffer handle
---@param cursor? integer[] Cursor position [row, col] (1-indexed)
---@param width? integer Window width
---@return integer Window handle
function H.setup_win(buf, cursor, width)
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  if cursor then
    vim.api.nvim_win_set_cursor(win, cursor)
  end
  if width then
    vim.api.nvim_win_set_width(win, width)
  end
  return win
end

--- Execute function with temporary buffer and window
---@param lines? string[] Lines to set in buffer
---@param cursor? integer[] Cursor position [row, col] (1-indexed)
---@param width? integer Window width
---@param fn fun(buf: integer, win: integer): any Function to execute
---@return any Result of fn
function H.with_win_buf(lines, cursor, width, fn)
  local buf = H.make_buf(lines)
  local win = H.setup_win(buf, cursor, width)
  local ok, result = pcall(fn, buf, win)
  vim.api.nvim_buf_delete(buf, { force = true })
  if not ok then
    error(result)
  end
  return result
end

--- Create a mock glimmer config for testing
---@param overrides? table Config overrides
---@return table Mock config
function H.make_config(overrides)
  local base = {
    enabled = true,
    disable_warnings = true,
    animations = {
      fade = {
        max_duration = 400,
        min_duration = 300,
        easing = "outQuad",
        chars_for_max_duration = 10,
        from_color = "#ff0000",
        to_color = "#00ff00",
      },
      pulse = {
        max_duration = 600,
        min_duration = 400,
        chars_for_max_duration = 15,
        pulse_count = 2,
        intensity = 1.2,
        from_color = "#0000ff",
        to_color = "#ffff00",
      },
    },
    overwrite = {
      search = { enabled = true },
      paste = { enabled = true },
      undo = { enabled = true },
      yank = { enabled = true },
    },
    support = {
      substitute = { enabled = true },
    },
    presets = {
      pulsar = { enabled = true },
    },
    refresh_interval_ms = 8,
    transparency_color = nil,
    virt_text = { priority = 2048 },
    hijack_ft_disabled = { "alpha", "snacks_dashboard" },
  }

  if overrides then
    base = vim.tbl_deep_extend("force", base, overrides)
  end
  return base
end

--- Setup a mock glimmer module for testing
---@param config? table Config to use
---@return table Mock glimmer module
function H.setup_glimmer(config)
  -- Clear any existing module cache
  package.loaded["tiny-glimmer"] = nil
  package.loaded["tiny-glimmer.init"] = nil
  package.loaded["tiny-glimmer.setup"] = nil
  package.loaded["tiny-glimmer.api"] = nil

  local glimmer = require("tiny-glimmer")
  glimmer.config = H.make_config(config)
  glimmer.hijack_done = false

  return glimmer
end

--- Create a mock animation settings table
---@param overrides? table Animation overrides
---@return table Animation settings
function H.make_animation(overrides)
  local base = {
    max_duration = 400,
    min_duration = 300,
    easing = "outQuad",
    chars_for_max_duration = 10,
    from_color = "#ff0000",
    to_color = "#00ff00",
  }

  if overrides then
    base = vim.tbl_extend("force", base, overrides)
  end
  return base
end

--- Generate unique ID for testing
---@return fun(): integer ID generator function
function H.uid_gen()
  local counter = 0
  return function()
    counter = counter + 1
    return counter
  end
end

--- Create a mock highlight group color
---@param color string|nil Hex color or nil
---@return integer Mock highlight color value
function H.mock_highlight_color(color)
  if not color or color == "None" then
    return nil
  end
  -- Convert hex to integer (simplified mock)
  if color:match("^#%x%x%x%x%x%x$") then
    return tonumber(color:sub(2), 16)
  end
  return 0
end

return H

local M = {}

-- Track active buffer attachments to prevent duplicates
local active_attachments = {}

---Merges overlapping or adjacent ranges
---@param ranges table[] List of ranges to merge
---@return table[] Merged ranges
local function merge_ranges(ranges)
  if #ranges == 0 then
    return {}
  end

  table.sort(ranges, function(a, b)
    if a.start_line == b.start_line then
      return a.start_col < b.start_col
    end
    return a.start_line < b.start_line
  end)

  local merged = {}
  local current = ranges[1]

  local function is_empty_range(r)
    return r.start_line == r.end_line and r.start_col == r.end_col
  end

  for i = 2, #ranges do
    local next_range = ranges[i]

    -- Check if ranges overlap or are adjacent
    if
      current.end_line < next_range.start_line
      or (current.end_line == next_range.start_line and current.end_col < next_range.start_col)
    then
      -- No overlap, add current range if not empty
      if not is_empty_range(current) then
        table.insert(merged, current)
      end
      current = next_range
    else
      -- Merge overlapping ranges
      current.end_line = math.max(current.end_line, next_range.end_line)
      if current.end_line == next_range.end_line then
        current.end_col = math.max(current.end_col, next_range.end_col)
      end
    end
  end

  -- Add the last range if not empty
  if not is_empty_range(current) then
    table.insert(merged, current)
  end

  return merged
end

---Handles text change animations with debouncing for multi-location edits
---@param callback function|nil Function to call with the merged ranges
---@param timeout? number Timeout in milliseconds to batch changes (default: from config)
---@return nil
function M.handle_text_change_animation(callback, timeout)
  if vim.fn.reg_executing() ~= "" then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()

  -- Prevent multiple simultaneous attachments on the same buffer
  if active_attachments[bufnr] then
    return
  end

  local ranges = {}
  local detach_listener = false
  local timer_handle = nil

  -- Get timeout from parameter or config
  if not timeout then
    local config = require("tiny-glimmer.config.defaults")
    timeout = config.text_change_batch_timeout_ms or 50
  end

  local function process_ranges()
    detach_listener = true
    active_attachments[bufnr] = nil
    if callback and #ranges > 0 then
      callback(merge_ranges(ranges))
    end
  end

  local function on_bytes(_, _, _, start_row, start_col, _, _, _, _, new_end_row, new_end_col, _)
    if detach_listener then
      return true
    end

    if vim.fn.reg_executing() ~= "" then
      detach_listener = true
      active_attachments[bufnr] = nil
      if timer_handle then
        vim.fn.timer_stop(timer_handle)
      end
      return true
    end

    -- Calculate the affected text range
    local end_row = start_row + new_end_row
    local end_col = start_col + new_end_col

    if end_row >= vim.api.nvim_buf_line_count(bufnr) then
      local last_line = vim.api.nvim_buf_get_lines(bufnr, -2, -1, false)[1]
      if last_line then
        end_col = #last_line
      end
    end

    table.insert(ranges, {
      start_line = start_row,
      start_col = start_col,
      end_line = end_row,
      end_col = end_col,
    })

    -- Debounce: restart timer on each edit
    if timer_handle then
      vim.fn.timer_stop(timer_handle)
    end
    timer_handle = vim.fn.timer_start(timeout, process_ranges)
  end

  active_attachments[bufnr] = true
  vim.api.nvim_buf_attach(bufnr, false, {
    on_bytes = on_bytes,
  })
end

return M

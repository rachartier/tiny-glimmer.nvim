local M = {}

---@param callback function|nil Function to call with the merged ranges
---@param timeout? number Timeout in milliseconds to batch changes (default: from config)
---@return nil
function M.handle_text_change_animation(callback, timeout)
  -- check macro execution and skip text_change animation if a macro is running
  if vim.fn.reg_executing() ~= "" then
    return
  end

  local ranges = {}
  local final_ranges = {}

  local insert = table.insert
  local max = math.max

  -- Flag to detach buffer listener
  local detach_listener = false

  local function on_bytes(
    _, -- event
    _, -- bufnr
    _, -- changedtick
    start_row,
    start_col,
    _, -- byte_offset
    _, -- old_end_row
    _, -- old_end_col
    _, -- old_byte_end
    new_end_row,
    new_end_col,
    _ -- new_byte_end
  )
    if detach_listener then
      return true
    end

    -- re-check macro execution during buffer change events
    if vim.fn.reg_executing() ~= "" then
      detach_listener = true
      return true
    end

    -- Calculate the affected text range
    local end_row = start_row + new_end_row
    local end_col = start_col + new_end_col

    if end_row >= vim.api.nvim_buf_line_count(0) then
      local last_line = vim.api.nvim_buf_get_lines(0, -2, -1, false)[1]
      if last_line then
        end_col = #last_line
      end
    end

    insert(ranges, {
      start_line = start_row,
      start_col = start_col,
      end_line = end_row,
      end_col = end_col,
    })
  end

  vim.api.nvim_buf_attach(0, false, {
    on_bytes = on_bytes,
  })

  -- Get timeout from parameter or config
  if not timeout then
    local config = require("tiny-glimmer.config.defaults")
    timeout = config.text_change_batch_timeout_ms or 50
  end

  vim.defer_fn(function()
    detach_listener = true

    local range_count = #ranges
    if range_count > 0 then
      table.sort(ranges, function(a, b)
        if a.start_line == b.start_line then
          return a.start_col < b.start_col
        end
        return a.start_line < b.start_line
      end)

      local current = ranges[1]

      local is_empty_range = function(r)
        return r.start_line == r.end_line and r.start_col == r.end_col
      end

      for i = 2, range_count do
        local next_range = ranges[i]

        -- Check if ranges overlap or are adjacent
        if
          current.end_line < next_range.start_line
          or (current.end_line == next_range.start_line and current.end_col < next_range.start_col)
        then
          -- No overlap, add current range if not empty
          if not is_empty_range(current) then
            insert(final_ranges, current)
          end
          current = next_range
        else
          -- Merge overlapping ranges (optimize the conditional)
          current.end_line = max(current.end_line, next_range.end_line)
          if current.end_line == next_range.end_line then
            current.end_col = max(current.end_col, next_range.end_col)
          end
        end
      end

      -- Add the last range if not empty
      if not is_empty_range(current) then
        insert(final_ranges, current)
      end
    end

    if callback then
      callback(final_ranges)
    end
  end, timeout)
end

return M

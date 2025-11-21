local M = {}

---Remove overlapping portions from ranges
---@param ranges table[] List of {start_line, start_col, end_line, end_col} ranges
---@return table[] Non-overlapping ranges
local function merge_ranges(ranges)
  if #ranges == 0 then
    return {}
  end

  -- Sort ranges by start line and then by start column
  table.sort(ranges, function(a, b)
    if a.start_line == b.start_line then
      return a.start_col < b.start_col
    end
    return a.start_line < b.start_line
  end)

  local final_ranges = {}

  for _, range in ipairs(ranges) do
    -- Only add non-empty ranges
    if range.start_line == range.end_line and range.start_col == range.end_col then
      goto continue
    end

    -- Check for overlap with previous ranges and adjust
    local adjusted_range = {
      start_line = range.start_line,
      start_col = range.start_col,
      end_line = range.end_line,
      end_col = range.end_col,
    }

    for _, prev_range in ipairs(final_ranges) do
      -- Check if ranges are on the same line and overlap
      if adjusted_range.start_line == prev_range.start_line and adjusted_range.end_line == prev_range.end_line then
        -- Check if current range overlaps with previous range
        if adjusted_range.start_col < prev_range.end_col and adjusted_range.end_col > prev_range.start_col then
          -- Overlapping! Adjust the current range to start after the previous one
          if adjusted_range.start_col < prev_range.end_col then
            adjusted_range.start_col = prev_range.end_col
          end
        end
      end
    end

    -- Only add if still non-empty after adjustment
    -- For multi-line ranges: check if different lines
    -- For single-line ranges: check if different columns
    local is_non_empty = adjusted_range.start_line < adjusted_range.end_line
      or (adjusted_range.start_line == adjusted_range.end_line and adjusted_range.start_col < adjusted_range.end_col)
    
    if is_non_empty then
      table.insert(final_ranges, adjusted_range)
    end

    ::continue::
  end

  return final_ranges
end

---Captures changes using on_bytes and triggers animation callback
---@param opts table Animation options
---@return function Function to call after operation completes
local function setup_change_detector(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local ranges = {}
  local detach_listener = false

  local function on_bytes(_, _, _, start_row, start_col, _, old_end_row, old_end_col, _, new_end_row, new_end_col, _)
    if detach_listener then
      return true
    end

    local buffer_line_count = vim.api.nvim_buf_line_count(bufnr)
    local end_row = start_row + new_end_row
    local end_col = start_col + new_end_col

    -- Adjust end column for changes at buffer end
    if end_row >= buffer_line_count then
      local last_line = vim.api.nvim_buf_get_lines(bufnr, -2, -1, false)[1]
      if last_line then
        end_col = #last_line
      end
    end

    -- Calculate the net change in text length
    local old_len = old_end_col
    local new_len = new_end_col
    local delta = new_len - old_len

    -- Adjust positions of all previously collected ranges that come after this change
    if delta ~= 0 then
      -- For single-line changes, adjust on same line
      if start_row == end_row then
        for _, prev_range in ipairs(ranges) do
          if prev_range.start_line == start_row then
            -- If previous range starts at or after this insertion, shift it
            if prev_range.start_col >= start_col then
              prev_range.start_col = prev_range.start_col + delta
              prev_range.end_col = prev_range.end_col + delta
            end
          end
        end
      -- For multi-line changes, adjust all subsequent lines
      elseif new_end_row > 0 then
        local line_delta = new_end_row - old_end_row
        for _, prev_range in ipairs(ranges) do
          -- Shift all ranges on lines at or after the insertion point
          if prev_range.start_line >= start_row then
            prev_range.start_line = prev_range.start_line + line_delta
            prev_range.end_line = prev_range.end_line + line_delta
          end
        end
      end
    end

    local range = {
      start_line = start_row,
      start_col = start_col,
      end_line = end_row,
      end_col = end_col,
    }

    -- Default: add the full range
    table.insert(ranges, range)
  end

  -- Attach buffer listener
  vim.api.nvim_buf_attach(bufnr, false, {
    on_bytes = on_bytes,
  })

  -- Return function to process collected ranges
  return function()
    vim.schedule(function()
      detach_listener = true

      local final_ranges = merge_ranges(ranges)

      if #final_ranges > 0 then
        require("tiny-glimmer.animation.factory")
          .get_instance()
          :create_text_animation(opts.default_animation, {
            base = { ranges = final_ranges },
          })
      end
    end)
  end
end

---Animate undo operation by capturing changes via on_bytes
---@param opts table Animation options
function M.undo(opts)
  local process_changes = setup_change_detector(opts)

  -- Schedule processing after hijack executes
  vim.schedule(process_changes)
end

---Animate redo operation by capturing changes via on_bytes
---@param opts table Animation options
function M.redo(opts)
  local process_changes = setup_change_detector(opts)

  -- Schedule processing after hijack executes
  vim.schedule(process_changes)
end

return M

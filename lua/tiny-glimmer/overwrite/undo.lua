local M = {}

---Merge overlapping or adjacent ranges
---@param ranges table[] List of {start_line, start_col, end_line, end_col} ranges
---@return table[] Merged ranges
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
  local current = ranges[1]

  for i = 2, #ranges do
    local next_range = ranges[i]

    -- Check if ranges overlap or are adjacent
    if
      current.end_line < next_range.start_line
      or (current.end_line == next_range.start_line and current.end_col < next_range.start_col)
    then
      -- No overlap, add current range and start new one
      if current.start_line ~= current.end_line or current.start_col ~= current.end_col then
        table.insert(final_ranges, current)
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

  if current.start_line ~= current.end_line or current.start_col ~= current.end_col then
    table.insert(final_ranges, current)
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

  local function on_bytes(_, _, _, start_row, start_col, _, _, _, _, new_end_row, new_end_col, _)
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

    table.insert(ranges, {
      start_line = start_row,
      start_col = start_col,
      end_line = end_row,
      end_col = end_col,
    })
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

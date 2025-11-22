local M = {}

---Standard interval merge algorithm
---@param ranges table[]
---@return table[]
local function merge_ranges(ranges)
  if #ranges < 2 then
    return ranges
  end

  table.sort(ranges, function(a, b)
    if a.start_line ~= b.start_line then
      return a.start_line < b.start_line
    end
    return a.start_col < b.start_col
  end)

  local merged = { ranges[1] }

  for i = 2, #ranges do
    local curr = ranges[i]
    local prev = merged[#merged]

    -- Overlap logic: checks if current starts before (or at) previous ends
    local is_overlap = curr.start_line < prev.end_line
      or (curr.start_line == prev.end_line and curr.start_col <= prev.end_col)

    if is_overlap then
      if
        curr.end_line > prev.end_line
        or (curr.end_line == prev.end_line and curr.end_col > prev.end_col)
      then
        prev.end_line = curr.end_line
        prev.end_col = curr.end_col
      end
    else
      table.insert(merged, curr)
    end
  end

  return merged
end

---Shifts previously recorded ranges if a new change happens above them
local function shift_ranges(ranges, start_row, start_col, row_delta, col_delta)
  if row_delta == 0 and col_delta == 0 then
    return
  end

  for _, r in ipairs(ranges) do
    if r.start_line > start_row then
      r.start_line = r.start_line + row_delta
      r.end_line = r.end_line + row_delta
    elseif row_delta == 0 and r.start_line == start_row and r.start_col >= start_col then
      r.start_col = r.start_col + col_delta
      r.end_col = r.end_col + col_delta
    end
  end
end

local function setup_change_detector(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local ranges = {}
  local detach = false

  local function on_bytes(
    _,
    _,
    _,
    start_row,
    start_col,
    _,
    old_end_row,
    old_end_col,
    _,
    new_end_row,
    new_end_col,
    _
  )
    if detach then
      return true
    end

    local end_row = start_row + new_end_row
    local end_col = start_col + new_end_col

    -- Safety: Clamp end_col to actual line length to prevent API errors on the last line
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if end_row < line_count then
      local line = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, true)[1]
      if line then
        end_col = math.min(end_col, #line)
      end
    end

    local row_delta = new_end_row - old_end_row
    local col_delta = new_end_col - old_end_col

    shift_ranges(ranges, start_row, start_col, row_delta, col_delta)

    if start_row == end_row and start_col == end_col then
      end_col = end_col + 1
    end

    table.insert(ranges, {
      start_line = start_row,
      start_col = start_col,
      end_line = end_row,
      end_col = end_col,
    })
  end

  vim.api.nvim_buf_attach(bufnr, false, { on_bytes = on_bytes })

  return function()
    vim.schedule(function()
      detach = true
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

local function handle_operation(opts)
  local process = setup_change_detector(opts)
  vim.schedule(process)
end

function M.undo(opts)
  handle_operation(opts)
end
function M.redo(opts)
  handle_operation(opts)
end

return M

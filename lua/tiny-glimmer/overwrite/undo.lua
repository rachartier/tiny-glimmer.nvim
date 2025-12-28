local M = {}

-- Assumes ranges are sorted and disjunct
local function sorted_ranges_disjunct(r1, r2)
  if r1.end_line < r2.start_line then
    return true
  elseif r1.end_line == r2.start_line then
    return r1.end_col < r2.start_col
  end
  return false
end

local function range_starts_before(r1, r2)
  if r1.start_line < r2.start_line then
    return true
  elseif r1.start_line == r2.start_line then
    return r1.start_col <= r2.start_col
  end
  return false
end

local function range_ends_after(r1, r2)
  if r1.end_line > r2.end_line then
    return true
  elseif r1.end_line == r2.end_line then
    return r1.end_col > r2.end_col
  end
  return false
end

local function empty_range(range)
  return range.start_line > range.end_line or (range.start_line == range.end_line and range.start_col >= range.end_col)
end

-- Search and insert the old range and modify all existing ranges according to the change
local function insert_range(ranges, old_range, new_range)
  if empty_range(old_range) and empty_range(new_range) then
    return
  end

  local i = 1
  while range_starts_before(ranges[i], old_range) do
    i = i + 1
  end

  -- Insert and merge with previous and following merges if needed
  -- There is at most one merge with a previous range (ranges were sorted and disjunct before insertion)
  if sorted_ranges_disjunct(ranges[i - 1], old_range) then
    table.insert(ranges, i, vim.deepcopy(old_range))
  else
    if range_ends_after(old_range, ranges[i - 1]) then
      -- new range not completely contained in the previous one
      ranges[i - 1].end_line = old_range.end_line
      ranges[i - 1].end_col = old_range.end_col
    end
    i = i - 1
  end

  -- There are possibly many merges with following ranges
  while not sorted_ranges_disjunct(ranges[i], ranges[i + 1]) do
    if range_ends_after(ranges[i + 1], ranges[i]) then
      ranges[i].end_line = ranges[i + 1].end_line
      ranges[i].end_col = ranges[i + 1].end_col
    end
    table.remove(ranges, i + 1)
  end

  -- Shift all ranges after the change (if needed)
  local delta_line = new_range.end_line - old_range.end_line
  local delta_col = new_range.end_col - old_range.end_col
  if delta_line == 0 and delta_col == 0 then
    return
  end

  -- This range is always guaranteed to contain both the start and the end of the changed text
  -- therefore we compare to the end
  if ranges[i].end_line == old_range.end_line then
    ranges[i].end_col = ranges[i].end_col + delta_col
  end
  ranges[i].end_line = ranges[i].end_line + delta_line
  if empty_range(ranges[i]) then
    table.remove(ranges, i)
  else
    i = i + 1
  end

  -- All following (disjunct) ranges are after the change either on the same line or not
  -- therefore we compare to the start
  for j = i, #ranges - 1 do
    if ranges[j].start_line == old_range.end_line then
      ranges[j].start_col = ranges[j].start_col + delta_col
    end
    if ranges[j].end_line == old_range.end_line then
      ranges[j].end_col = ranges[j].end_col + delta_col
    end
    ranges[j].start_line = ranges[j].start_line + delta_line
    ranges[j].end_line = ranges[j].end_line + delta_line
  end
end

local function add_guards(ranges)
  table.insert(ranges, 1, {
    start_line = -1, start_col = -1,
    end_line = -1, end_col = -1,
  })
  table.insert(ranges, {
    start_line = math.huge, start_col = math.huge,
    end_line = math.huge, end_col = math.huge,
  })
  return ranges
end

local function remove_guards(ranges)
  table.remove(ranges, 1)
  table.remove(ranges, #ranges)
  return ranges
end

local function offset2range(start_row, start_col, offset_row, offset_col)
  return {
    start_line = start_row,
    start_col = start_col,
    end_line = start_row + offset_row,
    -- `:h nvim_buf_attach`
    end_col = (offset_row == 0 and start_col or 0) + offset_col,
  }
end

local function setup_change_detector(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  -- Sorted list of disjunct recorded ranges with guards to simplify implementation
  -- Ranges are inclusive for lines and exclusive for columns
  local ranges = add_guards {}
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

    local old_range = offset2range(start_row, start_col, old_end_row, old_end_col)
    local new_range = offset2range(start_row, start_col, new_end_row, new_end_col)
    insert_range(ranges, old_range, new_range)
  end

  vim.api.nvim_buf_attach(bufnr, false, { on_bytes = on_bytes })

  return function()
    vim.schedule(function()
      detach = true
      if #ranges > 2 then
        require("tiny-glimmer.animation.factory")
          .get_instance()
          :create_text_animation(opts.default_animation, {
            base = { ranges = remove_guards(ranges) },
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

M._test = {
  add_guards = add_guards,
  remove_guards = remove_guards,
  insert_range = insert_range,
}

return M

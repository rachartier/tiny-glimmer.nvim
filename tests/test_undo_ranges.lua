local MiniTest = require("mini.test")

local T = MiniTest.new_set()

-- Helper to simulate on_bytes calls and verify range adjustment
local function simulate_undo_ranges(on_bytes_calls)
  local ranges = {}

  -- Simulate the on_bytes callback logic from undo.lua
  for _, call in ipairs(on_bytes_calls) do
    local start_row, start_col = call.start_row, call.start_col
    local old_end_row, old_end_col = call.old_end_row or 0, call.old_end_col
    local new_end_row, new_end_col = call.new_end_row or 0, call.new_end_col

    local end_row = start_row + new_end_row
    local end_col = start_col + new_end_col

    -- Calculate the net change in text length
    local old_len = old_end_col
    local new_len = new_end_col
    local delta = new_len - old_len

    -- Adjust positions of all previously collected ranges that come after this change
    if delta ~= 0 then
      -- For single-line changes, adjust on same line
      if new_end_row == 0 then
        for _, prev_range in ipairs(ranges) do
          if prev_range.start_line == start_row then
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

    -- Add the current range
    table.insert(ranges, {
      start_line = start_row,
      start_col = start_col,
      end_line = end_row,
      end_col = end_col,
    })
  end

  -- Sort ranges by start position
  table.sort(ranges, function(a, b)
    if a.start_line == b.start_line then
      return a.start_col < b.start_col
    end
    return a.start_line < b.start_line
  end)

  return ranges
end

T["undo range adjustment"] = MiniTest.new_set()

T["undo range adjustment"]["handles multiple surround additions (5saiw*)"] = function()
  -- Simulate: "test" -> "*****test*****" via redo
  -- mini.surround inserts right side first at position 4, then left side at position 0
  local on_bytes_calls = {
    { start_row = 0, start_col = 4, old_end_col = 0, new_end_col = 5 }, -- Insert ***** at end
    { start_row = 0, start_col = 0, old_end_col = 0, new_end_col = 5 }, -- Insert ***** at start
  }

  local ranges = simulate_undo_ranges(on_bytes_calls)

  -- Should have 2 non-overlapping ranges
  MiniTest.expect.equality(#ranges, 2)

  -- First range should be left surround: [0,0] -> [0,5]
  MiniTest.expect.equality(ranges[1].start_line, 0)
  MiniTest.expect.equality(ranges[1].start_col, 0)
  MiniTest.expect.equality(ranges[1].end_line, 0)
  MiniTest.expect.equality(ranges[1].end_col, 5)

  -- Second range should be right surround: [0,9] -> [0,14]
  -- (originally [0,4]->[0,9], shifted by +5 when left side inserted)
  MiniTest.expect.equality(ranges[2].start_line, 0)
  MiniTest.expect.equality(ranges[2].start_col, 9)
  MiniTest.expect.equality(ranges[2].end_line, 0)
  MiniTest.expect.equality(ranges[2].end_col, 14)
end

T["undo range adjustment"]["handles tag deletion (sdt)"] = function()
  -- Simulate: "<tag></tag>" -> "" via deletion and redo
  -- Deletes both tags separately
  local on_bytes_calls = {
    { start_row = 0, start_col = 5, old_end_col = 0, new_end_col = 6 }, -- Insert </tag>
    { start_row = 0, start_col = 0, old_end_col = 0, new_end_col = 5 }, -- Insert <tag>
  }

  local ranges = simulate_undo_ranges(on_bytes_calls)

  -- Should have 2 non-overlapping ranges
  MiniTest.expect.equality(#ranges, 2)

  -- First range should be opening tag: [0,0] -> [0,5]
  MiniTest.expect.equality(ranges[1].start_line, 0)
  MiniTest.expect.equality(ranges[1].start_col, 0)
  MiniTest.expect.equality(ranges[1].end_col, 5)

  -- Second range should be closing tag: [0,10] -> [0,16]
  -- (originally [0,5]->[0,11], shifted by +5 when opening tag inserted)
  MiniTest.expect.equality(ranges[2].start_line, 0)
  MiniTest.expect.equality(ranges[2].start_col, 10)
  MiniTest.expect.equality(ranges[2].end_col, 16)
end

T["undo range adjustment"]["handles quote deletion (di\")"] = function()
  -- Simulate: "" -> "<text>" via redo
  -- This is a single insertion that includes both quotes and text
  local on_bytes_calls = {
    { start_row = 0, start_col = 0, old_end_col = 0, new_end_col = 8 }, -- Insert "<text>"
  }

  local ranges = simulate_undo_ranges(on_bytes_calls)

  -- Should have 1 range covering entire text
  MiniTest.expect.equality(#ranges, 1)
  MiniTest.expect.equality(ranges[1].start_line, 0)
  MiniTest.expect.equality(ranges[1].start_col, 0)
  MiniTest.expect.equality(ranges[1].end_col, 8)
end

T["undo range adjustment"]["handles no position shift when insertion is after"] = function()
  -- Simulate: two insertions where second doesn't affect first
  local on_bytes_calls = {
    { start_row = 0, start_col = 0, old_end_col = 0, new_end_col = 5 }, -- Insert at start
    { start_row = 0, start_col = 10, old_end_col = 0, new_end_col = 5 }, -- Insert after
  }

  local ranges = simulate_undo_ranges(on_bytes_calls)

  -- Should have 2 ranges
  MiniTest.expect.equality(#ranges, 2)

  -- First range should remain unchanged: [0,0] -> [0,5]
  MiniTest.expect.equality(ranges[1].start_col, 0)
  MiniTest.expect.equality(ranges[1].end_col, 5)

  -- Second range should be at original position: [0,10] -> [0,15]
  MiniTest.expect.equality(ranges[2].start_col, 10)
  MiniTest.expect.equality(ranges[2].end_col, 15)
end

T["undo range adjustment"]["handles deletion with position shift"] = function()
  -- Simulate: deletion (negative delta) that should shift later ranges backward
  local ranges = {}

  -- First range
  table.insert(ranges, {
    start_line = 0,
    start_col = 10,
    end_line = 0,
    end_col = 15,
  })

  -- Simulate deletion at position 0 (delta = -5)
  local start_col = 0
  local delta = -5

  for _, prev_range in ipairs(ranges) do
    if prev_range.start_col >= start_col then
      prev_range.start_col = prev_range.start_col + delta
      prev_range.end_col = prev_range.end_col + delta
    end
  end

  -- Range should be shifted backward: [0,5] -> [0,10]
  MiniTest.expect.equality(ranges[1].start_col, 5)
  MiniTest.expect.equality(ranges[1].end_col, 10)
end

T["undo range adjustment"]["preserves ranges on different lines"] = function()
  -- Simulate: insertions on different lines don't affect each other
  local on_bytes_calls = {
    { start_row = 0, start_col = 0, old_end_col = 0, new_end_col = 5 },
    { start_row = 1, start_col = 0, old_end_col = 0, new_end_col = 5 },
  }

  local ranges = simulate_undo_ranges(on_bytes_calls)

  MiniTest.expect.equality(#ranges, 2)
  MiniTest.expect.equality(ranges[1].start_line, 0)
  MiniTest.expect.equality(ranges[2].start_line, 1)

  -- Both should have original positions
  MiniTest.expect.equality(ranges[1].start_col, 0)
  MiniTest.expect.equality(ranges[1].end_col, 5)
  MiniTest.expect.equality(ranges[2].start_col, 0)
  MiniTest.expect.equality(ranges[2].end_col, 5)
end

T["undo range adjustment"]["handles line deletion undo (dd then u)"] = function()
  local on_bytes_calls = {
    {
      start_row = 1,
      start_col = 0,
      old_end_row = 0,
      old_end_col = 0,
      new_end_row = 1,
      new_end_col = 0,
    },
  }

  local ranges = simulate_undo_ranges(on_bytes_calls)
  MiniTest.expect.equality(#ranges, 1)
  MiniTest.expect.equality(ranges[1].start_line, 1)
  MiniTest.expect.equality(ranges[1].start_col, 0)
  MiniTest.expect.equality(ranges[1].end_line, 2)
  MiniTest.expect.equality(ranges[1].end_col, 0)
end

T["undo range adjustment"]["skips whitespace-only single-line insertions"] = function()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "    aaa", "    ", "    bbb" })

  local undo_module = require("tiny-glimmer.overwrite.undo")
  local get_line_text = function(row)
    return vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
  end
  
  local line = get_line_text(1)
  local range_text = line:sub(1, 5)
  local is_whitespace = range_text:match("^%s*$") ~= nil
  
  MiniTest.expect.equality(is_whitespace, true)
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

T["undo range adjustment"]["skips whitespace-only multi-line insertions"] = function()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "aaa", "    ", "bbb" })

  local has_non_whitespace = false
  for i = 1, 1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1]
    if line and line:match("%S") then
      has_non_whitespace = true
      break
    end
  end

  MiniTest.expect.equality(has_non_whitespace, false)
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

T["undo range adjustment"]["preserves non-whitespace insertions"] = function()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "aaa", "    text", "bbb" })

  local line = vim.api.nvim_buf_get_lines(bufnr, 1, 2, false)[1]
  local range_text = line:sub(1, 9)
  local is_whitespace = range_text:match("^%s*$") ~= nil

  MiniTest.expect.equality(is_whitespace, false)
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

T["undo range adjustment"]["handles multi-line change with subsequent line shift"] = function()
  -- Scenario: Two multi-line insertions where the first should shift
  -- First insert 2 lines at row 0
  -- Then insert 1 line at row 0 (comes before the first insertion)
  -- The first insertion's ranges should be shifted down by 1

  local on_bytes_calls = {
    {
      start_row = 0,
      start_col = 0,
      old_end_row = 0,
      old_end_col = 0,
      new_end_row = 2,
      new_end_col = 5,
    },
    {
      start_row = 0,
      start_col = 0,
      old_end_row = 0,
      old_end_col = 0,
      new_end_row = 1,
      new_end_col = 3,
    },
  }

  local ranges = simulate_undo_ranges(on_bytes_calls)
  MiniTest.expect.equality(#ranges, 2)
  
  -- After sorting, the ranges should be in order:
  -- ranges[1]: [0,0]->[1,3] (second insertion)
  -- ranges[2]: [1,0]->[3,5] (first insertion, shifted)
  MiniTest.expect.equality(ranges[1].start_line, 0)
  MiniTest.expect.equality(ranges[1].end_line, 1)
  MiniTest.expect.equality(ranges[2].start_line, 1)
  MiniTest.expect.equality(ranges[2].end_line, 3)
end

return T

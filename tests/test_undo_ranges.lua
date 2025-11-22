local MiniTest = require("mini.test")
local undo = require("tiny-glimmer.overwrite.undo")

local T = MiniTest.new_set()

local shift_ranges = undo._test.shift_ranges
local merge_ranges = undo._test.merge_ranges

T["shift_ranges"] = MiniTest.new_set()

T["shift_ranges"]["no-op when deltas are zero"] = function()
  local ranges = {
    { start_line = 5, start_col = 10, end_line = 5, end_col = 20 },
  }

  shift_ranges(ranges, 0, 0, 0, 0)

  MiniTest.expect.equality(ranges[1].start_line, 5)
  MiniTest.expect.equality(ranges[1].start_col, 10)
  MiniTest.expect.equality(ranges[1].end_line, 5)
  MiniTest.expect.equality(ranges[1].end_col, 20)
end

T["shift_ranges"]["shifts ranges below change point"] = function()
  local ranges = {
    { start_line = 10, start_col = 0, end_line = 10, end_col = 5 },
  }

  shift_ranges(ranges, 0, 0, 2, 0)

  MiniTest.expect.equality(ranges[1].start_line, 12)
  MiniTest.expect.equality(ranges[1].end_line, 12)
end

T["shift_ranges"]["does not shift ranges above change point"] = function()
  local ranges = {
    { start_line = 5, start_col = 0, end_line = 5, end_col = 5 },
  }

  shift_ranges(ranges, 10, 0, 2, 0)

  MiniTest.expect.equality(ranges[1].start_line, 5)
  MiniTest.expect.equality(ranges[1].end_line, 5)
end

T["shift_ranges"]["shifts columns on same line"] = function()
  local ranges = {
    { start_line = 5, start_col = 10, end_line = 5, end_col = 20 },
  }

  shift_ranges(ranges, 5, 5, 0, 3)

  MiniTest.expect.equality(ranges[1].start_line, 5)
  MiniTest.expect.equality(ranges[1].start_col, 13)
  MiniTest.expect.equality(ranges[1].end_col, 23)
end

T["shift_ranges"]["does not shift columns before change point on same line"] = function()
  local ranges = {
    { start_line = 5, start_col = 2, end_line = 5, end_col = 4 },
  }

  shift_ranges(ranges, 5, 10, 0, 3)

  MiniTest.expect.equality(ranges[1].start_col, 2)
  MiniTest.expect.equality(ranges[1].end_col, 4)
end

T["shift_ranges"]["handles negative row delta"] = function()
  local ranges = {
    { start_line = 10, start_col = 0, end_line = 10, end_col = 5 },
  }

  shift_ranges(ranges, 0, 0, -2, 0)

  MiniTest.expect.equality(ranges[1].start_line, 8)
  MiniTest.expect.equality(ranges[1].end_line, 8)
end

T["shift_ranges"]["handles multiple ranges independently"] = function()
  local ranges = {
    { start_line = 3, start_col = 0, end_line = 3, end_col = 5 },
    { start_line = 10, start_col = 0, end_line = 10, end_col = 5 },
    { start_line = 15, start_col = 0, end_line = 15, end_col = 5 },
  }

  shift_ranges(ranges, 5, 0, 2, 0)

  MiniTest.expect.equality(ranges[1].start_line, 3)
  MiniTest.expect.equality(ranges[2].start_line, 12)
  MiniTest.expect.equality(ranges[3].start_line, 17)
end

T["merge_ranges"] = MiniTest.new_set()

T["merge_ranges"]["returns single range unchanged"] = function()
  local ranges = {
    { start_line = 5, start_col = 10, end_line = 5, end_col = 20 },
  }

  local merged = merge_ranges(ranges)

  MiniTest.expect.equality(#merged, 1)
  MiniTest.expect.equality(merged[1].start_line, 5)
  MiniTest.expect.equality(merged[1].end_line, 5)
end

T["merge_ranges"]["returns empty array unchanged"] = function()
  local ranges = {}
  local merged = merge_ranges(ranges)
  MiniTest.expect.equality(#merged, 0)
end

T["merge_ranges"]["merges overlapping ranges on same line"] = function()
  local ranges = {
    { start_line = 5, start_col = 0, end_line = 5, end_col = 10 },
    { start_line = 5, start_col = 5, end_line = 5, end_col = 15 },
  }

  local merged = merge_ranges(ranges)

  MiniTest.expect.equality(#merged, 1)
  MiniTest.expect.equality(merged[1].start_line, 5)
  MiniTest.expect.equality(merged[1].start_col, 0)
  MiniTest.expect.equality(merged[1].end_line, 5)
  MiniTest.expect.equality(merged[1].end_col, 15)
end

T["merge_ranges"]["merges adjacent ranges"] = function()
  local ranges = {
    { start_line = 5, start_col = 0, end_line = 5, end_col = 10 },
    { start_line = 5, start_col = 10, end_line = 5, end_col = 20 },
  }

  local merged = merge_ranges(ranges)

  MiniTest.expect.equality(#merged, 1)
  MiniTest.expect.equality(merged[1].start_col, 0)
  MiniTest.expect.equality(merged[1].end_col, 20)
end

T["merge_ranges"]["keeps non-overlapping ranges separate"] = function()
  local ranges = {
    { start_line = 5, start_col = 0, end_line = 5, end_col = 10 },
    { start_line = 10, start_col = 0, end_line = 10, end_col = 10 },
  }

  local merged = merge_ranges(ranges)

  MiniTest.expect.equality(#merged, 2)
end

T["merge_ranges"]["handles ranges across multiple lines"] = function()
  local ranges = {
    { start_line = 5, start_col = 0, end_line = 7, end_col = 10 },
    { start_line = 6, start_col = 5, end_line = 8, end_col = 5 },
  }

  local merged = merge_ranges(ranges)

  MiniTest.expect.equality(#merged, 1)
  MiniTest.expect.equality(merged[1].start_line, 5)
  MiniTest.expect.equality(merged[1].end_line, 8)
end

T["merge_ranges"]["sorts ranges before merging"] = function()
  local ranges = {
    { start_line = 10, start_col = 0, end_line = 10, end_col = 5 },
    { start_line = 5, start_col = 0, end_line = 5, end_col = 5 },
    { start_line = 7, start_col = 0, end_line = 7, end_col = 5 },
  }

  local merged = merge_ranges(ranges)

  MiniTest.expect.equality(#merged, 3)
  MiniTest.expect.equality(merged[1].start_line, 5)
  MiniTest.expect.equality(merged[2].start_line, 7)
  MiniTest.expect.equality(merged[3].start_line, 10)
end

T["merge_ranges"]["merges multiple overlapping ranges"] = function()
  local ranges = {
    { start_line = 5, start_col = 0, end_line = 5, end_col = 10 },
    { start_line = 5, start_col = 5, end_line = 5, end_col = 15 },
    { start_line = 5, start_col = 12, end_line = 5, end_col = 20 },
  }

  local merged = merge_ranges(ranges)

  MiniTest.expect.equality(#merged, 1)
  MiniTest.expect.equality(merged[1].start_col, 0)
  MiniTest.expect.equality(merged[1].end_col, 20)
end

T["merge_ranges"]["handles complex mixed scenario"] = function()
  local ranges = {
    { start_line = 1, start_col = 0, end_line = 1, end_col = 5 },
    { start_line = 1, start_col = 3, end_line = 2, end_col = 5 },
    { start_line = 5, start_col = 0, end_line = 5, end_col = 10 },
    { start_line = 10, start_col = 0, end_line = 10, end_col = 5 },
    { start_line = 10, start_col = 3, end_line = 10, end_col = 8 },
  }

  local merged = merge_ranges(ranges)

  MiniTest.expect.equality(#merged, 3)
  MiniTest.expect.equality(merged[1].start_line, 1)
  MiniTest.expect.equality(merged[1].end_line, 2)
  MiniTest.expect.equality(merged[2].start_line, 5)
  MiniTest.expect.equality(merged[3].start_line, 10)
  MiniTest.expect.equality(merged[3].end_col, 8)
end

return T

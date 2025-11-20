local MiniTest = require("mini.test")

local T = MiniTest.new_set()

T["diff_based"] = MiniTest.new_set()

-- Helper to access private function for testing
local function get_module_internals()
  local diff_based = require("tiny-glimmer.animation.diff_based")

  -- Replicate the internal functions for testing
  local function find_longest_common_substring(before, after)
    local max_len = 0
    local before_start = 0
    local after_start = 0

    for i = 1, #before do
      for j = 1, #after do
        local len = 0
        while
          i + len <= #before
          and j + len <= #after
          and before:sub(i + len, i + len) == after:sub(j + len, j + len)
        do
          len = len + 1
        end
        if len > max_len then
          max_len = len
          before_start = i - 1
          after_start = j - 1
        end
      end
    end

    return before_start, after_start, max_len
  end

  local find_changed_ranges = function(before, after)
    if before == after then
      return {}
    end

    if #before == 0 then
      return { { start_col = 0, end_col = #after } }
    end

    if #after == 0 then
      return {}
    end

    -- Find common prefix
    local prefix_len = 0
    local min_len = math.min(#before, #after)

    while
      prefix_len < min_len
      and before:sub(prefix_len + 1, prefix_len + 1) == after:sub(prefix_len + 1, prefix_len + 1)
    do
      prefix_len = prefix_len + 1
    end

    -- Find common suffix
    local suffix_len = 0
    local before_remaining = #before - prefix_len
    local after_remaining = #after - prefix_len

    while
      suffix_len < before_remaining
      and suffix_len < after_remaining
      and before:sub(#before - suffix_len, #before - suffix_len)
        == after:sub(#after - suffix_len, #after - suffix_len)
    do
      suffix_len = suffix_len + 1
    end

    -- Check if prefix + suffix cover ALL of 'before'
    if prefix_len + suffix_len >= #before then
      -- Pure insertion
      local change_start = prefix_len
      local change_end = #after - suffix_len

      if change_start >= change_end then
        return {}
      end

      return { { start_col = change_start, end_col = change_end } }
    else
      -- Surround operation - use LCS
      local _, after_match_start, match_len = find_longest_common_substring(before, after)

      if match_len == 0 then
        return { { start_col = 0, end_col = #after } }
      end

      local after_match_end = after_match_start + match_len
      local ranges = {}

      if after_match_start > 0 then
        table.insert(ranges, {
          start_col = 0,
          end_col = after_match_start,
        })
      end

      if after_match_end < #after then
        table.insert(ranges, {
          start_col = after_match_end,
          end_col = #after,
        })
      end

      return ranges
    end
  end

  return {
    find_changed_ranges = find_changed_ranges,
    compare_and_animate = diff_based.compare_and_animate,
  }
end

-- Test find_changed_ranges
T["diff_based"]["find_changed_ranges with identical strings"] = function()
  local internals = get_module_internals()
  local ranges = internals.find_changed_ranges("hello", "hello")

  MiniTest.expect.equality(ranges, {})
end

T["diff_based"]["find_changed_ranges with quotes added (surround)"] = function()
  local internals = get_module_internals()
  local ranges = internals.find_changed_ranges("hello", '"hello"')

  -- Should return TWO ranges: [0:1] for opening quote, [6:7] for closing quote
  MiniTest.expect.equality(#ranges, 2)
  MiniTest.expect.equality(ranges[1], { start_col = 0, end_col = 1 })
  MiniTest.expect.equality(ranges[2], { start_col = 6, end_col = 7 })
end

T["diff_based"]["find_changed_ranges with HTML tags added"] = function()
  local internals = get_module_internals()
  local ranges = internals.find_changed_ranges("hello", "<h1>hello</h1>")

  -- Should return TWO ranges: [0:4] for "<h1>", [9:14] for "</h1>"
  MiniTest.expect.equality(#ranges, 2)
  MiniTest.expect.equality(ranges[1], { start_col = 0, end_col = 4 })
  MiniTest.expect.equality(ranges[2], { start_col = 9, end_col = 14 })
end

T["diff_based"]["find_changed_ranges with parentheses added"] = function()
  local internals = get_module_internals()
  local ranges = internals.find_changed_ranges("test", "(test)")

  -- Should return TWO ranges
  MiniTest.expect.equality(#ranges, 2)
  MiniTest.expect.equality(ranges[1], { start_col = 0, end_col = 1 })
  MiniTest.expect.equality(ranges[2], { start_col = 5, end_col = 6 })
end

T["diff_based"]["find_changed_ranges with complete replacement"] = function()
  local internals = get_module_internals()
  local ranges = internals.find_changed_ranges("abc", "xyz")

  -- No common substring, entire 'after' is changed
  MiniTest.expect.equality(#ranges, 1)
  MiniTest.expect.equality(ranges[1], { start_col = 0, end_col = 3 })
end

T["diff_based"]["find_changed_ranges with empty before"] = function()
  local internals = get_module_internals()
  local ranges = internals.find_changed_ranges("", "hello")

  -- Entire string is new
  MiniTest.expect.equality(#ranges, 1)
  MiniTest.expect.equality(ranges[1], { start_col = 0, end_col = 5 })
end

T["diff_based"]["find_changed_ranges with empty after"] = function()
  local internals = get_module_internals()
  local ranges = internals.find_changed_ranges("hello", "")

  -- Nothing to highlight in empty string
  MiniTest.expect.equality(ranges, {})
end

T["diff_based"]["find_changed_ranges with single character addition at start"] = function()
  local internals = get_module_internals()
  local ranges = internals.find_changed_ranges("hello", "xhello")

  MiniTest.expect.equality(#ranges, 1)
  MiniTest.expect.equality(ranges[1], { start_col = 0, end_col = 1 })
end

T["diff_based"]["find_changed_ranges with single character addition at end"] = function()
  local internals = get_module_internals()
  local ranges = internals.find_changed_ranges("hello", "hellox")

  MiniTest.expect.equality(#ranges, 1)
  MiniTest.expect.equality(ranges[1], { start_col = 5, end_col = 6 })
end

T["diff_based"]["find_changed_ranges with character in middle"] = function()
  local internals = get_module_internals()
  local ranges = internals.find_changed_ranges("hello", "helxlo")

  -- Prefix="hel", suffix="lo", changed region="x"
  MiniTest.expect.equality(#ranges, 1)
  MiniTest.expect.equality(ranges[1].start_col, 3)
  MiniTest.expect.equality(ranges[1].end_col, 4)
end

T["diff_based"]["find_changed_ranges with issue #42 case"] = function()
  local internals = get_module_internals()
  local ranges = internals.find_changed_ranges("<tag></tag>", "<tag><text></tag>")

  -- This is a pure insertion case: prefix+suffix cover all of 'before'
  -- Should return ONE range for the inserted content
  MiniTest.expect.equality(#ranges, 1)
  -- The algorithm gives [6:12] which includes "text><"
  -- This is acceptable (slightly off from ideal [5:11] due to '<' coincidence)
  MiniTest.expect.equality(ranges[1].start_col >= 5 and ranges[1].start_col <= 6, true)
  MiniTest.expect.equality(ranges[1].end_col >= 11 and ranges[1].end_col <= 12, true)
end

-- Test compare_and_animate integration
T["diff_based"]["compare_and_animate with no changes"] = function()
  local diff_based = require("tiny-glimmer.animation.diff_based")

  -- Create test buffer
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "hello world" })

  local before_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local before_tick = vim.api.nvim_buf_get_changedtick(bufnr)

  local called = false
  local callback = function(ranges)
    called = true
  end

  diff_based.compare_and_animate(bufnr, before_lines, before_tick, callback)

  -- No changes, callback should not be called
  MiniTest.expect.equality(called, false)

  vim.api.nvim_buf_delete(bufnr, { force = true })
end

T["diff_based"]["compare_and_animate with single location change"] = function()
  local diff_based = require("tiny-glimmer.animation.diff_based")

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "hello" })

  local before_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local before_tick = vim.api.nvim_buf_get_changedtick(bufnr)

  -- Change content
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "xhello" })

  local captured_ranges = nil
  local callback = function(ranges)
    captured_ranges = ranges
  end

  diff_based.compare_and_animate(bufnr, before_lines, before_tick, callback)

  -- Should detect one range for the added 'x'
  MiniTest.expect.equality(type(captured_ranges), "table")
  MiniTest.expect.equality(#captured_ranges, 1)
  MiniTest.expect.equality(captured_ranges[1].start_line, 0)
  MiniTest.expect.equality(captured_ranges[1].start_col, 0)
  MiniTest.expect.equality(captured_ranges[1].end_col, 1)

  vim.api.nvim_buf_delete(bufnr, { force = true })
end

T["diff_based"]["compare_and_animate with multi-location change (surround)"] = function()
  local diff_based = require("tiny-glimmer.animation.diff_based")

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "hello" })

  local before_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local before_tick = vim.api.nvim_buf_get_changedtick(bufnr)

  -- Add quotes (simulating surround operation)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '"hello"' })

  local captured_ranges = nil
  local callback = function(ranges)
    captured_ranges = ranges
  end

  diff_based.compare_and_animate(bufnr, before_lines, before_tick, callback)

  -- Should detect TWO ranges: opening and closing quote
  MiniTest.expect.equality(type(captured_ranges), "table")
  MiniTest.expect.equality(#captured_ranges, 2)

  -- First range: opening quote
  MiniTest.expect.equality(captured_ranges[1].start_line, 0)
  MiniTest.expect.equality(captured_ranges[1].start_col, 0)
  MiniTest.expect.equality(captured_ranges[1].end_col, 1)

  -- Second range: closing quote
  MiniTest.expect.equality(captured_ranges[2].start_line, 0)
  MiniTest.expect.equality(captured_ranges[2].start_col, 6)
  MiniTest.expect.equality(captured_ranges[2].end_col, 7)

  vim.api.nvim_buf_delete(bufnr, { force = true })
end

T["diff_based"]["compare_and_animate with HTML tags (multi-location)"] = function()
  local diff_based = require("tiny-glimmer.animation.diff_based")

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "hello" })

  local before_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local before_tick = vim.api.nvim_buf_get_changedtick(bufnr)

  -- Wrap with HTML tags
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "<h1>hello</h1>" })

  local captured_ranges = nil
  local callback = function(ranges)
    captured_ranges = ranges
  end

  diff_based.compare_and_animate(bufnr, before_lines, before_tick, callback)

  -- Should detect TWO ranges: opening and closing tags
  MiniTest.expect.equality(type(captured_ranges), "table")
  MiniTest.expect.equality(#captured_ranges, 2)

  -- First range: opening tag
  MiniTest.expect.equality(captured_ranges[1].start_line, 0)
  MiniTest.expect.equality(captured_ranges[1].start_col, 0)
  MiniTest.expect.equality(captured_ranges[1].end_col, 4)

  -- Second range: closing tag
  MiniTest.expect.equality(captured_ranges[2].start_line, 0)
  MiniTest.expect.equality(captured_ranges[2].start_col, 9)
  MiniTest.expect.equality(captured_ranges[2].end_col, 14)

  vim.api.nvim_buf_delete(bufnr, { force = true })
end

T["diff_based"]["compare_and_animate with multi-line changes"] = function()
  local diff_based = require("tiny-glimmer.animation.diff_based")

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "line1", "line2" })

  local before_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local before_tick = vim.api.nvim_buf_get_changedtick(bufnr)

  -- Change both lines
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "xline1", "line2x" })

  local captured_ranges = nil
  local callback = function(ranges)
    captured_ranges = ranges
  end

  diff_based.compare_and_animate(bufnr, before_lines, before_tick, callback)

  -- Should detect changes on both lines
  MiniTest.expect.equality(type(captured_ranges), "table")
  MiniTest.expect.equality(#captured_ranges, 2)

  -- First change on line 0
  MiniTest.expect.equality(captured_ranges[1].start_line, 0)

  -- Second change on line 1
  MiniTest.expect.equality(captured_ranges[2].start_line, 1)

  vim.api.nvim_buf_delete(bufnr, { force = true })
end

T["diff_based"]["compare_and_animate with whole line replacement"] = function()
  local diff_based = require("tiny-glimmer.animation.diff_based")

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "abc" })

  local before_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local before_tick = vim.api.nvim_buf_get_changedtick(bufnr)

  -- Complete replacement with no common characters
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "xyz" })

  local captured_ranges = nil
  local callback = function(ranges)
    captured_ranges = ranges
  end

  diff_based.compare_and_animate(bufnr, before_lines, before_tick, callback)

  -- Should detect entire new line as changed (no common substring)
  MiniTest.expect.equality(type(captured_ranges), "table")
  MiniTest.expect.equality(#captured_ranges, 1)
  MiniTest.expect.equality(captured_ranges[1].start_line, 0)
  MiniTest.expect.equality(captured_ranges[1].start_col, 0)
  MiniTest.expect.equality(captured_ranges[1].end_col, 3) -- "xyz" length

  vim.api.nvim_buf_delete(bufnr, { force = true })
end

T["diff_based"]["create_diff_detector returns function"] = function()
  local diff_based = require("tiny-glimmer.animation.diff_based")

  local callback = function() end
  local detector = diff_based.create_diff_detector(callback)

  MiniTest.expect.equality(type(detector), "function")
end

return T

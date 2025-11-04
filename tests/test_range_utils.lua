local H = require("tests.helpers")
local MiniTest = require("mini.test")

local T = MiniTest.new_set()

local range_utils = require("tiny-glimmer.range_utils")

T["range_utils"] = MiniTest.new_set()

T["range_utils"]["get_cursor_range returns current cursor as range"] = function()
  local buf = H.make_buf({ "test line 1", "test line 2" })
  H.setup_win(buf, { 1, 5 })

  local range = range_utils.get_cursor_range()

  MiniTest.expect.equality(range.start_line, 0)
  MiniTest.expect.equality(range.start_col, 5)
  MiniTest.expect.equality(range.end_line, 0)
  MiniTest.expect.equality(range.end_col, 6)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["range_utils"]["get_cursor_range handles different positions"] = function()
  local buf = H.make_buf({ "line 1", "line 2", "line 3" })
  H.setup_win(buf, { 2, 3 })

  local range = range_utils.get_cursor_range()

  MiniTest.expect.equality(range.start_line, 1)
  MiniTest.expect.equality(range.start_col, 3)
  MiniTest.expect.equality(range.end_line, 1)
  MiniTest.expect.equality(range.end_col, 4)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["range_utils"]["get_line_range returns full line range"] = function()
  local buf = H.make_buf({ "test line 1", "test line 2" })
  vim.api.nvim_set_current_buf(buf)

  local range = range_utils.get_line_range(1)

  MiniTest.expect.equality(range.start_line, 0)
  MiniTest.expect.equality(range.start_col, 0)
  MiniTest.expect.equality(range.end_line, 0)
  MiniTest.expect.equality(range.end_col, 11)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["range_utils"]["get_line_range uses current line when 0 is passed"] = function()
  local buf = H.make_buf({ "line 1", "line 2", "line 3" })
  H.setup_win(buf, { 2, 0 })

  local range = range_utils.get_line_range(0)

  MiniTest.expect.equality(range.start_line, 1)
  MiniTest.expect.equality(range.start_col, 0)
  MiniTest.expect.equality(range.end_line, 1)
  MiniTest.expect.equality(range.end_col, 6)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["range_utils"]["get_line_range handles empty lines"] = function()
  local buf = H.make_buf({ "", "non-empty" })
  vim.api.nvim_set_current_buf(buf)

  local range = range_utils.get_line_range(1)

  MiniTest.expect.equality(range.start_line, 0)
  MiniTest.expect.equality(range.start_col, 0)
  MiniTest.expect.equality(range.end_line, 0)
  MiniTest.expect.equality(range.end_col, 0)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["range_utils"]["get_visual_range returns visual selection range"] = function()
  local buf = H.make_buf({ "line 1", "line 2", "line 3" })
  vim.api.nvim_set_current_buf(buf)

  -- Set visual selection marks
  vim.fn.setpos("'<", { buf, 1, 2, 0 })
  vim.fn.setpos("'>", { buf, 2, 4, 0 })

  local range = range_utils.get_visual_range()

  MiniTest.expect.equality(type(range), "table")
  MiniTest.expect.equality(range.start_line, 0)
  MiniTest.expect.equality(range.start_col, 1)
  MiniTest.expect.equality(range.end_line, 1)
  MiniTest.expect.equality(range.end_col, 4)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["range_utils"]["get_visual_range returns nil when no selection"] = function()
  local buf = H.make_buf({ "line 1" })
  vim.api.nvim_set_current_buf(buf)

  -- Clear marks
  vim.fn.setpos("'<", { 0, 0, 0, 0 })
  vim.fn.setpos("'>", { 0, 0, 0, 0 })

  local range = range_utils.get_visual_range()

  MiniTest.expect.equality(range, nil)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["range_utils"]["get_yank_range returns yank range"] = function()
  local buf = H.make_buf({ "line 1", "line 2" })
  vim.api.nvim_set_current_buf(buf)

  -- Set yank marks
  vim.fn.setpos("'[", { buf, 1, 1, 0 })
  vim.fn.setpos("']", { buf, 1, 6, 0 })

  local range = range_utils.get_yank_range()

  MiniTest.expect.equality(type(range), "table")
  MiniTest.expect.equality(range.start_line, 0)
  MiniTest.expect.equality(range.start_col, 0)
  MiniTest.expect.equality(range.end_line, 0)
  MiniTest.expect.equality(range.end_col, 6)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["range_utils"]["get_yank_range returns nil when no yank"] = function()
  local buf = H.make_buf({ "line 1" })
  vim.api.nvim_set_current_buf(buf)

  -- Clear marks
  vim.fn.setpos("'[", { 0, 0, 0, 0 })
  vim.fn.setpos("']", { 0, 0, 0, 0 })

  local range = range_utils.get_yank_range()

  MiniTest.expect.equality(range, nil)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["range_utils"]["get_yank_range handles multi-line yanks"] = function()
  local buf = H.make_buf({ "line 1", "line 2", "line 3" })
  vim.api.nvim_set_current_buf(buf)

  -- Set multi-line yank marks
  vim.fn.setpos("'[", { buf, 1, 1, 0 })
  vim.fn.setpos("']", { buf, 3, 3, 0 })

  local range = range_utils.get_yank_range()

  MiniTest.expect.equality(type(range), "table")
  MiniTest.expect.equality(range.start_line, 0)
  MiniTest.expect.equality(range.start_col, 0)
  MiniTest.expect.equality(range.end_line, 2)
  MiniTest.expect.equality(range.end_col, 3)

  vim.api.nvim_buf_delete(buf, { force = true })
end

return T

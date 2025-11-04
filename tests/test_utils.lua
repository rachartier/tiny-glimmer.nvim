local H = require("tests.helpers")
local MiniTest = require("mini.test")

local T = MiniTest.new_set()

local utils = require("tiny-glimmer.utils")

T["utils"] = MiniTest.new_set()

T["utils"]["int_to_hex converts integer to hex color"] = function()
  local result = utils.int_to_hex(16711680)
  MiniTest.expect.equality(result, "#FF0000")
end

T["utils"]["int_to_hex converts black color"] = function()
  local result = utils.int_to_hex(0)
  MiniTest.expect.equality(result, "#000000")
end

T["utils"]["int_to_hex converts white color"] = function()
  local result = utils.int_to_hex(16777215)
  MiniTest.expect.equality(result, "#FFFFFF")
end

T["utils"]["int_to_hex returns None for nil"] = function()
  local result = utils.int_to_hex(nil)
  MiniTest.expect.equality(result, "None")
end

T["utils"]["hex_to_rgb converts hex to RGB table"] = function()
  local result = utils.hex_to_rgb("#FF0000")

  MiniTest.expect.equality(result.r, 255)
  MiniTest.expect.equality(result.g, 0)
  MiniTest.expect.equality(result.b, 0)
end

T["utils"]["hex_to_rgb handles lowercase hex"] = function()
  local result = utils.hex_to_rgb("#00ff00")

  MiniTest.expect.equality(result.r, 0)
  MiniTest.expect.equality(result.g, 255)
  MiniTest.expect.equality(result.b, 0)
end

T["utils"]["hex_to_rgb handles NONE"] = function()
  local result = utils.hex_to_rgb("NONE")

  MiniTest.expect.equality(result.r, 0)
  MiniTest.expect.equality(result.g, 0)
  MiniTest.expect.equality(result.b, 0)
end

T["utils"]["rgb_to_hex converts RGB table to hex"] = function()
  local result = utils.rgb_to_hex({ r = 255, g = 0, b = 0 })
  MiniTest.expect.equality(result, "#FF0000")
end

T["utils"]["rgb_to_hex handles black"] = function()
  local result = utils.rgb_to_hex({ r = 0, g = 0, b = 0 })
  MiniTest.expect.equality(result, "#000000")
end

T["utils"]["rgb_to_hex handles white"] = function()
  local result = utils.rgb_to_hex({ r = 255, g = 255, b = 255 })
  MiniTest.expect.equality(result, "#FFFFFF")
end

T["utils"]["rgb_to_hex handles mixed values"] = function()
  local result = utils.rgb_to_hex({ r = 128, g = 64, b = 32 })
  MiniTest.expect.equality(result, "#804020")
end

T["utils"]["hex_to_rgb and rgb_to_hex are reversible"] = function()
  local original = "#A1B2C3"
  local rgb = utils.hex_to_rgb(original)
  local result = utils.rgb_to_hex(rgb)
  MiniTest.expect.equality(result, original)
end

T["utils"]["clamp restricts value to min-max range"] = function()
  MiniTest.expect.equality(utils.clamp(50, 0, 100), 50)
  MiniTest.expect.equality(utils.clamp(-10, 0, 100), 0)
  MiniTest.expect.equality(utils.clamp(150, 0, 100), 100)
end

T["utils"]["clamp handles edge values"] = function()
  MiniTest.expect.equality(utils.clamp(0, 0, 100), 0)
  MiniTest.expect.equality(utils.clamp(100, 0, 100), 100)
end

T["utils"]["clamp handles negative ranges"] = function()
  MiniTest.expect.equality(utils.clamp(-50, -100, 0), -50)
  MiniTest.expect.equality(utils.clamp(-150, -100, 0), -100)
  MiniTest.expect.equality(utils.clamp(10, -100, 0), 0)
end

T["utils"]["get_range_last_modification returns range from marks"] = function()
  local buf = H.make_buf({ "line 1", "line 2", "line 3" })
  vim.api.nvim_set_current_buf(buf)

  vim.api.nvim_buf_set_mark(buf, "[", 1, 2, {})
  vim.api.nvim_buf_set_mark(buf, "]", 2, 5, {})

  local range = utils.get_range_last_modification(buf)

  MiniTest.expect.equality(range.start_line, 0)
  MiniTest.expect.equality(range.start_col, 2)
  MiniTest.expect.equality(range.end_line, 1)
  MiniTest.expect.equality(range.end_col, 5)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["utils"]["get_range_yank returns range from yank marks"] = function()
  local buf = H.make_buf({ "test line 1", "test line 2" })
  vim.api.nvim_set_current_buf(buf)

  vim.fn.setpos("'[", { buf, 1, 3, 0 })
  vim.fn.setpos("']", { buf, 1, 7, 0 })

  local range = utils.get_range_yank()

  MiniTest.expect.equality(range.start_line, 0)
  MiniTest.expect.equality(range.start_col, 2)
  MiniTest.expect.equality(range.end_line, 0)
  MiniTest.expect.equality(range.end_col, 7)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["utils"]["get_visual_range_yank returns visual selection marks"] = function()
  local buf = H.make_buf({ "line 1", "line 2", "line 3" })
  vim.api.nvim_set_current_buf(buf)

  vim.api.nvim_buf_set_mark(buf, "<", 1, 2, {})
  vim.api.nvim_buf_set_mark(buf, ">", 2, 4, {})

  local range = utils.get_visual_range_yank()

  MiniTest.expect.equality(range.start_line, 1)
  MiniTest.expect.equality(range.start_col, 2)
  MiniTest.expect.equality(range.end_line, 2)
  MiniTest.expect.equality(range.end_col, 4)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["utils"]["set_extmark creates extmark at position"] = function()
  local buf = H.make_buf({ "test line" })
  vim.api.nvim_set_current_buf(buf)

  local ns_id = vim.api.nvim_create_namespace("test_ns")
  local extmark_id = utils.set_extmark(0, ns_id, 0, { end_col = 4 })

  MiniTest.expect.equality(type(extmark_id), "number")

  local extmarks = vim.api.nvim_buf_get_extmarks(buf, ns_id, 0, -1, {})
  MiniTest.expect.equality(#extmarks, 1)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["utils"]["set_extmark handles negative line numbers"] = function()
  local buf = H.make_buf({ "test line" })
  vim.api.nvim_set_current_buf(buf)

  local ns_id = vim.api.nvim_create_namespace("test_ns_neg")
  local extmark_id = utils.set_extmark(-1, ns_id, 0, { end_col = 4 })

  MiniTest.expect.equality(type(extmark_id), "number")

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["utils"]["set_extmark handles negative column numbers"] = function()
  local buf = H.make_buf({ "test line" })
  vim.api.nvim_set_current_buf(buf)

  local ns_id = vim.api.nvim_create_namespace("test_ns_neg_col")
  local extmark_id = utils.set_extmark(0, ns_id, -1, { end_col = 4 })

  MiniTest.expect.equality(type(extmark_id), "number")

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["utils"]["max_number is valid 32-bit signed max"] = function()
  MiniTest.expect.equality(utils.max_number, 2147483647)
end

return T

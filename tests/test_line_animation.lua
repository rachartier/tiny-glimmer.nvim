local H = require("tests.helpers")
local MiniTest = require("mini.test")

local T = MiniTest.new_set()

T["LineAnimation"] = MiniTest.new_set()

local namespace = require("tiny-glimmer.namespace").tiny_glimmer_animation_ns

local function count_extmarks(buf)
  return #vim.api.nvim_buf_get_extmarks(buf, namespace, 0, -1, {})
end

T["LineAnimation"]["draws in its own buffer after the window changes"] = function()
  local Effect = require("tiny-glimmer.animation.effect")
  package.loaded["tiny-glimmer.animation.premade.line"] = nil
  local LineAnimation = require("tiny-glimmer.animation.premade.line")

  local lines = { "one", "two", "three" }
  local buf_a = H.make_buf(lines)
  local buf_b = H.make_buf(lines)

  local win_a = H.setup_win(buf_a, { 2, 0 })
  vim.cmd("vsplit")
  local win_b = H.setup_win(buf_b, { 1, 0 })

  vim.api.nvim_set_current_win(win_a)

  local effect = Effect.new({
    easing = "linear",
    min_duration = 500,
    max_duration = 500,
    chars_for_max_duration = 1,
  }, function(_, progress)
    return "#ff0000", progress
  end)
  local animation = LineAnimation.new(effect, {
    base = { range = { start_line = 1, start_col = 0, end_line = 1, end_col = 0 } },
  })
  animation:start(10)

  vim.api.nvim_set_current_win(win_b)
  vim.wait(50)

  MiniTest.expect.equality(count_extmarks(buf_a) > 0, true)
  MiniTest.expect.equality(count_extmarks(buf_b), 0)

  animation:stop()
  vim.api.nvim_win_close(win_b, true)
  vim.api.nvim_buf_delete(buf_a, { force = true })
  vim.api.nvim_buf_delete(buf_b, { force = true })
end

return T

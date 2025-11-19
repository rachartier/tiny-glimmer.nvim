local M = {}

local diff_based = require("tiny-glimmer.animation.diff_based")

local function create_callback(opts)
  return function(ranges)
    if #ranges == 0 then
      return
    end
    
    -- Create a single animation with multiple ranges
    require("tiny-glimmer.animation.factory")
      .get_instance()
      :create_text_animation(opts.default_animation, {
        base = { ranges = ranges },
      })
  end
end

---Animate undo operation by comparing state after hijack executes
---@param opts table Animation options
function M.undo(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local before_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local before_tick = vim.api.nvim_buf_get_changedtick(bufnr)

  -- Don't execute undo here - let hijack handle it
  -- Schedule comparison after hijack executes
  vim.schedule(function()
    diff_based.compare_and_animate(bufnr, before_lines, before_tick, create_callback(opts))
  end)
end

---Animate redo operation by comparing state after hijack executes
---@param opts table Animation options
function M.redo(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local before_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local before_tick = vim.api.nvim_buf_get_changedtick(bufnr)

  -- Don't execute redo here - let hijack handle it
  -- Schedule comparison after hijack executes
  vim.schedule(function()
    diff_based.compare_and_animate(bufnr, before_lines, before_tick, create_callback(opts))
  end)
end

return M

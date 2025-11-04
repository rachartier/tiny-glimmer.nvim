-- Example 2: Yank highlighting
-- Automatically highlight yanked text with an animation

local glimmer = require("tiny-glimmer.lib")

-- Setup autocmd to trigger on text yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("GlimmerYank", { clear = true }),
  callback = function()
    -- Get the yanked region
    local event = vim.v.event

    if event.operator ~= "y" then
      return
    end

    -- Get the range from marks
    local start_pos = vim.api.nvim_buf_get_mark(0, "[")
    local end_pos = vim.api.nvim_buf_get_mark(0, "]")

    if start_pos[1] == 0 or end_pos[1] == 0 then
      return
    end

    -- Create animation on yanked text
    glimmer.create_text_animation({
      range = {
        start_line = start_pos[1] - 1,
        start_col = start_pos[2],
        end_line = end_pos[1] - 1,
        end_col = end_pos[2] + 1,
      },
      duration = 300,
      from_color = "#4EC9B0",
      to_color = "Normal",
      effect = "fade",
      easing = "outQuad",
    })
  end,
})

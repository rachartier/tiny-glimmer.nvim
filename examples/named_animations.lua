-- Example 5: Named animations with manual control
-- Create animations that can be started and stopped on demand

local glimmer = require("tiny-glimmer.lib")

-- Start a persistent animation
vim.keymap.set("n", "<leader>as", function()
  local r = glimmer.get_cursor_range()

  r.start_col = 0
  r.end_col = 999

  glimmer.create_named_animation("my-animation", {
    range = r,
    duration = 3000, -- Long duration
    from_color = "#FF0000",
    to_color = "#0000FF",
    effect = "rainbow",
    on_complete = function()
      print("Animation completed!")
    end,
  })
  print("Animation started")
end, { desc = "Start named animation" })

-- Stop the animation
vim.keymap.set("n", "<leader>ax", function()
  glimmer.stop_animation("my-animation")
  print("Animation stopped")
end, { desc = "Stop named animation" })

-- Example: Animate multiple lines with individual control
vim.keymap.set("n", "<leader>am", function()
  for i = 1, 5 do
    local line = vim.fn.line(".") - 1 + i

    glimmer.create_named_animation("line-" .. i, {
      range = {
        start_line = line,
        start_col = 0,
        end_line = line,
        end_col = 999,
      },
      duration = 500 + (i * 50), -- Stagger durations
      from_color = "#FF6B6B",
      to_color = "Normal",
      effect = "fade",
    })
  end
end, { desc = "Animate multiple lines" })

-- Stop all multi-line animations
vim.keymap.set("n", "<leader>aM", function()
  for i = 1, 5 do
    glimmer.stop_animation("line-" .. i)
  end
end, { desc = "Stop all line animations" })

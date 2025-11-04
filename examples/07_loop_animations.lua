local glimmer = require("tiny-glimmer.lib")

-- Example 1: Infinite loop animation on current line
-- Animation will loop forever until stopped manually
vim.keymap.set("n", "<leader>li", function()
  glimmer.named_animate_range("infinite_pulse", "pulse", glimmer.get_line_range(0), {
    loop = true,
    loop_count = 0, -- 0 = infinite
  })
end)

-- Stop the infinite animation
vim.keymap.set("n", "<leader>ls", function()
  glimmer.stop_animation("infinite_pulse")
end)

-- Example 2: Loop animation 3 times on cursor line
vim.keymap.set("n", "<leader>l3", function()
  glimmer.cursor_line("bounce", {
    loop = true,
    loop_count = 3,
  })
end)

-- Example 3: Loop animation 5 times on visual selection
vim.keymap.set("v", "<leader>l5", function()
  glimmer.visual_selection("fade", {
    loop = true,
    loop_count = 5,
  })
end)

-- Example 4: Create an infinite rainbow effect that can be stopped
vim.keymap.set("n", "<leader>lr", function()
  glimmer.named_animate_range("rainbow_loop", "rainbow", glimmer.get_line_range(0), {
    loop = true,
    loop_count = 0,
  })
end)

-- Example 5: Create multiple looping animations on different lines
vim.keymap.set("n", "<leader>lm", function()
  local line = vim.api.nvim_win_get_cursor(0)[1]

  -- First line loops 2 times
  glimmer.animate_range("pulse", glimmer.get_line_range(line), {
    loop = true,
    loop_count = 2,
  })

  -- Second line loops 3 times
  glimmer.animate_range("pulse", glimmer.get_line_range(line + 1), {
    loop = true,
    loop_count = 3,
  })

  -- Third line loops 4 times
  glimmer.animate_range("pulse", glimmer.get_line_range(line + 2), {
    loop = true,
    loop_count = 4,
  })
end)

-- Example 6: Use loop with create_animation for precise control
vim.keymap.set("n", "<leader>lc", function()
  glimmer.create_animation({
    range = glimmer.get_line_range(0),
    duration = 500,
    from_color = "#ff0000",
    to_color = "#00ff00",
    effect = "fade",
    easing = "inOutQuad",
    loop = true,
    loop_count = 2,
    on_complete = function()
      print("Loop animation completed!")
    end,
  })
end)

-- Example 7: Create a pulsing search highlight effect
vim.keymap.set("n", "<leader>lh", function()
  local word = vim.fn.expand("<cword>")
  local matches = {}

  -- Find all occurrences of word in current buffer
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    local col = 1
    while true do
      local start, finish = string.find(line, word, col, true)
      if not start then
        break
      end
      table.insert(matches, {
        start_line = i - 1,
        start_col = start - 1,
        end_line = i - 1,
        end_col = finish,
      })
      col = finish + 1
    end
  end

  -- Animate each match with infinite loop
  for idx, range in ipairs(matches) do
    glimmer.named_animate_range("search_" .. idx, "pulse", range, {
      loop = true,
      loop_count = 0, -- infinite
    })
  end
end)

-- Stop all search highlights
vim.keymap.set("n", "<leader>lH", function()
  for i = 1, 100 do
    glimmer.stop_animation("search_" .. i)
  end
end)

-- Example: Multi-Range Animations
-- Demonstrates animating multiple ranges simultaneously with a single animation call

local lib = require("tiny-glimmer.lib")

-- Create a test buffer
vim.cmd("enew")
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "Hello world",
  "This is a test",
})

-- Example 1: Animate two ranges on the same line (simulating surround operation)
-- Highlights both the opening and closing quotes
vim.api.nvim_buf_set_lines(0, 0, 1, false, { '"Hello" world' })
lib.create_animation({
  ranges = {
    { start_line = 0, start_col = 0, end_line = 0, end_col = 1 }, -- Opening quote
    { start_line = 0, start_col = 7, end_line = 0, end_col = 8 }, -- Closing quote
  },
  from_color = "#ff0000",
  to_color = "#00ff00",
  duration = 500,
  effect = "fade",
})

-- Example 2: Animate ranges on different lines
vim.defer_fn(function()
  lib.create_animation({
    ranges = {
      { start_line = 0, start_col = 0, end_line = 0, end_col = 5 }, -- "Hello" on line 1
      { start_line = 1, start_col = 0, end_line = 1, end_col = 4 }, -- "This" on line 2
    },
    from_color = "#0000ff",
    to_color = "#ffff00",
    duration = 500,
    effect = "fade",
  })
end, 1000)

-- Example 3: Animate HTML tag addition (opening and closing tags)
vim.defer_fn(function()
  vim.api.nvim_buf_set_lines(0, 0, 1, false, { "<h1>Hello</h1> world" })
  lib.create_animation({
    ranges = {
      { start_line = 0, start_col = 0, end_line = 0, end_col = 4 }, -- "<h1>"
      { start_line = 0, start_col = 9, end_line = 0, end_col = 14 }, -- "</h1>"
    },
    from_color = "#ff00ff",
    to_color = "#00ffff",
    duration = 500,
    effect = "fade",
  })
end, 2000)

-- Example 4: Named multi-range animation that can be stopped
vim.defer_fn(function()
  lib.create_named_animation("multi_highlight", {
    ranges = {
      { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
      { start_line = 1, start_col = 0, end_line = 1, end_col = 4 },
    },
    from_color = "#ffffff",
    to_color = "#000000",
    duration = 1000,
    effect = "fade",
    loop = true,
    loop_count = 0, -- Infinite loop
  })

  -- Stop after 3 seconds
  vim.defer_fn(function()
    lib.stop_animation("multi_highlight")
    print("Stopped multi-range animation")
  end, 3000)
end, 3000)

-- Use Cases:
-- 1. Surround operations (adding quotes, parentheses, tags)
-- 2. Multi-cursor edits
-- 3. Replace operations that affect multiple locations
-- 4. Highlighting matching pairs (brackets, tags, etc.)
-- 5. Undo/redo operations that change multiple locations

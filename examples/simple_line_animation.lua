-- Example 1: Simple cursor line animation
-- This example shows how to animate the current line when pressing a key

local glimmer = require("tiny-glimmer.lib")

-- Animate current line with a fade effect
vim.keymap.set("n", "<leader>al", function()
  glimmer.create_line_animation({
    range = glimmer.get_line_range(0), -- 0 = current line
    duration = 300,
    from_color = "#FF6B6B",
    to_color = "Normal",
    effect = "fade",
    easing = "outQuad",
  })
end, { desc = "Animate current line" })

-- Animate with a pulse effect
vim.keymap.set("n", "<leader>ap", function()
  glimmer.create_line_animation({
    range = glimmer.get_line_range(0),
    duration = 500,
    from_color = "Visual",
    to_color = "Normal",
    effect = "pulse",
  })
end, { desc = "Pulse current line" })

-- Rainbow animation on current line
vim.keymap.set("n", "<leader>ar", function()
  glimmer.create_line_animation({
    range = glimmer.get_line_range(0),
    duration = 1000,
    from_color = "#000000", -- Not used in rainbow effect
    to_color = "#000000",
    effect = "rainbow",
  })
end, { desc = "Rainbow current line" })

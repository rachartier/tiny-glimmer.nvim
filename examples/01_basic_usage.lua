local glimmer = require("tiny-glimmer.lib")

-- Animate current line
vim.keymap.set("n", "<leader>al", function()
  glimmer.cursor_line("pulse")
end)

-- Animate next character
vim.keymap.set("n", "<leader>ac", function()
  local r = glimmer.get_cursor_range()

  r.end_col = r.start_col + 2

  glimmer.animate_range("fade", r)
end)

-- Different effects
vim.keymap.set("n", "<leader>a1", function()
  glimmer.cursor_line("fade")
end)

vim.keymap.set("n", "<leader>a2", function()
  glimmer.cursor_line("pulse")
end)

vim.keymap.set("n", "<leader>a3", function()
  glimmer.cursor_line("bounce")
end)

vim.keymap.set("n", "<leader>a4", function()
  glimmer.cursor_line("rainbow")
end)

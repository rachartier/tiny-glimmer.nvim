local glimmer = require("tiny-glimmer.lib")

-- Start and stop named animations
vim.keymap.set("n", "<leader>as", function()
  glimmer.named_animate_range(
    "my_anim",
    "rainbow",
    glimmer.get_line_range(0),
    { max_duration = 5000 }
  )
end)

vim.keymap.set("n", "<leader>ax", function()
  glimmer.stop_animation("my_anim")
end)

-- Multiple named animations
vim.keymap.set("n", "<leader>am", function()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  for i = 0, 2 do
    glimmer.named_animate_range("anim_" .. i, "fade", glimmer.get_line_range(line + i))
  end
end)

vim.keymap.set("n", "<leader>aM", function()
  for i = 0, 2 do
    glimmer.stop_animation("anim_" .. i)
  end
end)

-- Animation with callback
vim.keymap.set("n", "<leader>ac", function()
  glimmer.create_line_animation({
    range = glimmer.get_line_range(0),
    duration = 1000,
    from_color = "Visual",
    to_color = "Normal",
    effect = "fade",
    on_complete = function()
      print("Done!")
    end,
  })
end)

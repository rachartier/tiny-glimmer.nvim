-- Example 8: Visual selection animations
-- Animate visual selections and ranges

local glimmer = require("tiny-glimmer.lib")

-------------------------------------------
-- Example 1: Animate visual selection
-------------------------------------------
vim.keymap.set("v", "<leader>av", function()
  -- Get the visual selection range
  local range = glimmer.get_visual_range()

  if range then
    glimmer.create_text_animation({
      range = range,
      duration = 500,
      from_color = "#C678DD",
      to_color = "Normal",
      effect = "fade",
    })
  end
end, { desc = "Animate visual selection" })

-------------------------------------------
-- Example 2: Rainbow visual selection
-------------------------------------------
vim.keymap.set("v", "<leader>aR", function()
  vim.cmd("normal! ")

  local range = glimmer.get_visual_range()

  if range then
    glimmer.create_text_animation({
      range = range,
      duration = 1500,
      from_color = "#000000",
      to_color = "#000000",
      effect = "rainbow",
    })
  end
end, { desc = "Rainbow visual selection" })

-------------------------------------------
-- Example 3: Animate around cursor word
-------------------------------------------
vim.keymap.set("n", "<leader>aw", function()
  -- Get word under cursor boundaries
  local word_start = vim.fn.searchpos("\\<", "bnW")
  local word_end = vim.fn.searchpos("\\>", "nW")

  if word_start[1] > 0 and word_end[1] > 0 then
    glimmer.create_text_animation({
      range = {
        start_line = word_start[1] - 1,
        start_col = word_start[2] - 1,
        end_line = word_end[1] - 1,
        end_col = word_end[2],
      },
      duration = 400,
      from_color = "#E5C07B",
      to_color = "Normal",
      effect = "bounce",
    })
  end
end, { desc = "Animate word under cursor" })

-------------------------------------------
-- Example 4: Animate paragraph
-------------------------------------------
vim.keymap.set("n", "<leader>aP", function()
  local start_line = vim.fn.search("^$", "bnW") + 1
  local end_line = vim.fn.search("^$", "nW") - 1

  if end_line < start_line then
    end_line = vim.fn.line("$")
  end

  for line = start_line, end_line do
    glimmer.create_line_animation({
      range = {
        start_line = line - 1,
        start_col = 0,
        end_line = line - 1,
        end_col = 999,
      },
      duration = 600,
      from_color = "#61AFEF",
      to_color = "Normal",
      effect = "left_to_right",
    })
  end
end, { desc = "Animate paragraph" })

-------------------------------------------
-- Example 5: Animate entire buffer
-------------------------------------------
vim.keymap.set("n", "<leader>aB", function()
  local total_lines = vim.fn.line("$")

  -- Animate all lines with a cascading effect
  for i = 1, total_lines do
    vim.defer_fn(function()
      glimmer.create_line_animation({
        range = {
          start_line = i - 1,
          start_col = 0,
          end_line = i - 1,
          end_col = 999,
        },
        duration = 300,
        from_color = "#98C379",
        to_color = "Normal",
        effect = "fade",
      })
    end, i * 20) -- 20ms delay between each line
  end
end, { desc = "Animate entire buffer (cascade)" })

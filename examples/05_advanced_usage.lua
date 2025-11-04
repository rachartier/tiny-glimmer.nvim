-- Advanced Usage Examples
-- Complex animation scenarios using helper functions

local glimmer = require("tiny-glimmer.lib")

-- Animate multiple ranges simultaneously
-- Creates animations for current line and 2 lines above/below
vim.keymap.set("n", "<leader>amr", function()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  for offset = -2, 2 do
    local line = current_line + offset
    local range = {
      start_line = line - 1,
      start_col = 0,
      end_line = line,
      end_col = 0,
    }
    glimmer.animate_range("fade", range)
  end
end, { desc = "Animate multiple ranges" })

-- Search and highlight all matches of word under cursor
-- Iterates through buffer finding all occurrences
vim.keymap.set("n", "<leader>ash", function()
  local word = vim.fn.expand("<cword>")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for line_num, line_text in ipairs(lines) do
    local start_col = 1
    while true do
      local match_start, match_end = string.find(line_text, word, start_col, true)
      if not match_start then
        break
      end
      local range = {
        start_line = line_num - 1,
        start_col = match_start - 1,
        end_line = line_num - 1,
        end_col = match_end,
      }
      glimmer.animate_range("pulse", range)
      start_col = match_end + 1
    end
  end
end, { desc = "Highlight all word matches" })

-- Progress indicator based on line length percentage
-- Animates portion of current line corresponding to progress
local function animate_progress(percent)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local line_content = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
  local total_length = #line_content
  local progress_length = math.floor(total_length * percent / 100)
  if progress_length > 0 then
    local range = {
      start_line = line - 1,
      start_col = 0,
      end_line = line - 1,
      end_col = progress_length,
    }
    glimmer.animate_range("fade", range)
  end
end

vim.keymap.set("n", "<leader>ap1", function()
  animate_progress(25)
end, { desc = "Show 25% progress" })
vim.keymap.set("n", "<leader>ap2", function()
  animate_progress(50)
end, { desc = "Show 50% progress" })
vim.keymap.set("n", "<leader>ap3", function()
  animate_progress(75)
end, { desc = "Show 75% progress" })
vim.keymap.set("n", "<leader>ap4", function()
  animate_progress(100)
end, { desc = "Show 100% progress" })

-- Diff-style highlighting for added/changed/deleted lines
vim.keymap.set("n", "<leader>ada", function()
  glimmer.cursor_line("fade")
end, { desc = "Highlight as added" })

vim.keymap.set("n", "<leader>adc", function()
  glimmer.cursor_line("fade")
end, { desc = "Highlight as changed" })

vim.keymap.set("n", "<leader>add", function()
  glimmer.cursor_line("fade")
end, { desc = "Highlight as deleted" })

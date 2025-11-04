-- Example 3: Enhanced search with animations
-- Animate the search match when navigating with n/N

local glimmer = require("tiny-glimmer.lib")

-- Helper function to get search match range
local function get_search_range()
  local search_pattern = vim.fn.getreg("/")
  if search_pattern == "" then
    return nil
  end

  local pos = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  
  -- Find match on current line
  local start_col = vim.fn.match(line, search_pattern)
  if start_col == -1 then
    return nil
  end

  local match_text = vim.fn.matchstr(line, search_pattern)
  
  return {
    start_line = pos[1] - 1,
    start_col = start_col,
    end_line = pos[1] - 1,
    end_col = start_col + #match_text,
  }
end

-- Animate on next match
vim.keymap.set("n", "n", function()
  vim.cmd("normal! n")
  
  local range = get_search_range()
  if range then
    glimmer.create_animation({
      range = range,
      duration = 400,
      from_color = "#FFD700",
      to_color = "Normal",
      effect = "pulse",
    })
  end
end, { desc = "Next search with animation" })

-- Animate on previous match
vim.keymap.set("n", "N", function()
  vim.cmd("normal! N")
  
  local range = get_search_range()
  if range then
    glimmer.create_animation({
      range = range,
      duration = 400,
      from_color = "#FFD700",
      to_color = "Normal",
      effect = "pulse",
    })
  end
end, { desc = "Previous search with animation" })

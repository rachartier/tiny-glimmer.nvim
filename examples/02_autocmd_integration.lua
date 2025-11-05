local glimmer = require("tiny-glimmer.lib")

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    if vim.v.event.operator == "y" then
      local range = glimmer.get_yank_range()
      if range then
        glimmer.animate_range("fade", range)
      end
    end
  end,
})

-- Pulsar effect on cursor movement
local last_line = vim.api.nvim_win_get_cursor(0)[1]
vim.api.nvim_create_autocmd("CursorMoved", {
  callback = function()
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    if current_line ~= last_line then
      glimmer.named_animate_range("current_line", "fade", glimmer.get_line_range(current_line))
      last_line = current_line
    end
  end,
})

-- Animate when entering insert mode
vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    glimmer.cursor_line({ name = "fade", settings = { from_color = "DiffAdd" } })
  end,
})

-- Animate diagnostic updates
vim.api.nvim_create_autocmd("DiagnosticChanged", {
  callback = function()
    local diagnostics = vim.diagnostic.get(0)
    if #diagnostics > 0 then
      local diag = diagnostics[1]
      glimmer.animate_range("pulse", {
        start_line = diag.lnum,
        start_col = 0,
        end_line = diag.lnum,
        end_col = 100,
      }, { from_color = "DiagnosticError" })
    end
  end,
})

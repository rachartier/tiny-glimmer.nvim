local M = {}

local animation_group = require("tiny-glimmer.namespace").animation_group

local function search(opts, search_pattern)
  local buf = vim.api.nvim_get_current_buf()

  -- Fix for flash.nvim
  -- Need to wait for the cursor to be updated, and a simple vim.schedule is still too early
  vim.defer_fn(function()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local matches = vim.fn.matchbufline(buf, search_pattern, cursor_pos[1], cursor_pos[1])

    if vim.tbl_isempty(matches) then
      return
    end

    local range = {
      start_line = cursor_pos[1] - 1,
      start_col = cursor_pos[2],
      end_line = cursor_pos[1] - 1,
      end_col = cursor_pos[2] + #matches[1].text,
    }

    require("tiny-glimmer.animation.factory")
      .get_instance()
      :create_named_text_animation("search", opts.default_animation, {
        base = {
          range = range,
        },
      })
  end, 5)
end

function M.setup(opts)
  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = animation_group,
    callback = function()
      local cmd_type = vim.fn.getcmdtype()
      if cmd_type == "/" or cmd_type == "?" then
        M.search_on_line(opts)
      end
    end,
  })
end

function M.search_on_line(opts)
  search(opts, vim.fn.getreg("/"))
end

function M.search_next(opts)
  search(opts, vim.fn.getreg("/"))
end

function M.search_prev(opts)
  search(opts, vim.fn.getreg("/"))
end

function M.search_under_cursor(opts)
  local word_under_cursor = vim.fn.expand("<cword>")
  search(opts, word_under_cursor)
end

return M

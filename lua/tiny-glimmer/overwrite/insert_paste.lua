local M = {}

local diff_based = require("tiny-glimmer.animation.diff_based")

local function create_callback(opts)
  return function(ranges)
    if #ranges == 0 then
      return
    end

    require("tiny-glimmer.animation.factory")
      .get_instance()
      :create_text_animation(opts.default_animation, {
        base = { ranges = ranges },
      })
  end
end

---Setup insert mode paste animation tracking
---@param opts table Animation options
function M.setup(opts)
  local animation_group = require("tiny-glimmer.namespace").animation_group

  vim.api.nvim_create_autocmd("TextChangedI", {
    group = animation_group,
    callback = function()
      -- Use a flag to track if we should check for paste
      if vim.g._tiny_glimmer_insert_paste_pending then
        vim.g._tiny_glimmer_insert_paste_pending = nil

        local bufnr = vim.api.nvim_get_current_buf()
        local cur_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        -- Compare with stored state
        if vim.g._tiny_glimmer_before_lines then
          local before_lines = vim.g._tiny_glimmer_before_lines
          local before_tick = vim.g._tiny_glimmer_before_tick
          vim.g._tiny_glimmer_before_lines = nil
          vim.g._tiny_glimmer_before_tick = nil

          vim.schedule(function()
            diff_based.compare_and_animate(bufnr, before_lines, before_tick, create_callback(opts))
          end)
        end
      end
    end,
  })

  -- Track <c-r> keypresses
  local prev_key = nil
  local prev_mode = nil
  local ctrl_r_byte = 18

  vim.on_key(function(key)
    local mode = vim.api.nvim_get_mode().mode
    local key_byte = key:byte()

    if prev_key == ctrl_r_byte and prev_mode == "i" and mode == "i" then
      -- Store buffer state before paste
      local bufnr = vim.api.nvim_get_current_buf()
      vim.g._tiny_glimmer_before_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      vim.g._tiny_glimmer_before_tick = vim.api.nvim_buf_get_changedtick(bufnr)
      vim.g._tiny_glimmer_insert_paste_pending = true
    end

    prev_key = key_byte
    prev_mode = mode
  end)
end

return M

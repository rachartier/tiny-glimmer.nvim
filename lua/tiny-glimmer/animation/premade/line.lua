---@class LineAnimation
---@field cursor_line_enabled boolean Whether to show special cursor line animation
---@field cursor_line_color string|nil Hex color code for cursor line highlight
---@field virtual_text_priority number Priority level for virtual text rendering
---@field animation GlimmerAnimation Animation effect instance

local LineAnimation = {}
LineAnimation.__index = LineAnimation

local utils = require("tiny-glimmer.utils")
local namespace = require("tiny-glimmer.namespace").tiny_glimmer_animation_ns
local AnimationEffect = require("tiny-glimmer.glimmer_animation")

--- Creates anew LineAnimation Instance
---@param effect any The animiation effect implementation to use
---@param opts table Configuration options
---@return LineAnimation The created LineAnimation instance
function LineAnimation.new(effect, opts)
  local self = setmetatable({}, LineAnimation)

  if not opts.base then
    error("opts.base is required")
  end

  self.virtual_text_priority = opts.virtual_text_priority or 128

  local cursor_line_hl = utils.get_highlight("CursorLine").bg
  local animation_opts = opts.base

  self.cursor_line_enabled = false

  if cursor_line_hl ~= nil and cursor_line_hl ~= "None" then
    self.cursor_line_enabled = true
    animation_opts = vim.tbl_extend("force", opts.base, {
      overwrite_to_color = utils.int_to_hex(cursor_line_hl),
    })
  end

  -- Add loop options if provided
  if opts.loop ~= nil then
    animation_opts = vim.tbl_extend("force", animation_opts, {
      loop = opts.loop,
      loop_count = opts.loop_count or 0,
    })
  end

  self.animation = AnimationEffect.new(effect, animation_opts)

  return self
end

local function apply_hl(self, line)
  local line_index = self.animation.range.start_line
  local hl_group = self.animation:get_hl_group()
  local window = self.animation.window
  if self.cursor_line_enabled and vim.api.nvim_win_is_valid(window) then
    local cursor_position = vim.api.nvim_win_get_cursor(window)

    if cursor_position[1] - 1 == line_index then
      hl_group = self.animation:get_overwrite_hl_group()
    end
  end

  utils.set_extmark(line - 1, namespace, 0, {
    id = self.animation:get_reserved_id(),
    end_col = 0,
    hl_eol = true,
    end_row = line,
    hl_group = hl_group,
    priority = self.virtual_text_priority,
  }, self.animation.buffer)
end

function LineAnimation:start(refresh_interval_ms, on_complete)
  local length = self.animation.range.end_line - self.animation.range.start_line + 1

  local buf = self.animation.buffer

  self.animation:start(refresh_interval_ms, length, {
    on_update = function(update_progress)
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end

      vim.api.nvim_buf_clear_namespace(
        buf,
        namespace,
        self.animation.range.start_line,
        self.animation.range.start_line + 1
      )

      for i = 1, length do
        apply_hl(self, i + self.animation.range.start_line)
      end
    end,
    on_complete = on_complete,
  })
end

function LineAnimation:stop()
  self.animation:stop()
end

return LineAnimation

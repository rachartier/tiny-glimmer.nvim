---@class TextAnimation
---@field content string[] Lines of text being animated
---@field event_type string Vim's register type (v, V, or ^V)
---@field event Event Event type information
---@field operation string Vim operator that triggered animation (y, d, c)
---@field id number Unique identifier for this animation instance
---@field cursor_line_enabled boolean Whether to show special cursor line animation
---@field cursor_line_color string|nil Hex color code for cursor line highlight
---@field virtual_text_priority number Priority level for virtual text rendering
---@field animation GlimmerAnimation Animation effect instance

---@class Event
---@field is_visual boolean Whether the event is a visual selection
---@field is_line boolean Whether the event is a line-wise operation
---@field is_visual_block boolean Whether the event is a block-wise visual operation
---@field is_paste boolean Whether the event is a paste operation

local TextAnimation = {}
TextAnimation.__index = TextAnimation

local MAX_END_COL = 99999

local utils = require("tiny-glimmer.utils")
local namespace = require("tiny-glimmer.namespace").tiny_glimmer_animation_ns
local AnimationEffect = require("tiny-glimmer.glimmer_animation")

---Creates a new TextAnimation instance
---@param effect any The animation effect implementation to use
---@param opts table Configuration options
---@return TextAnimation The created TextAnimation instance
function TextAnimation.new(effect, opts)
  if not opts.base then
    error("opts.base is required")
  end

  local self = setmetatable({}, TextAnimation)

  self.buffer = vim.api.nvim_get_current_buf()
  self.virtual_text_priority = opts.virtual_text_priority or 128
  self.event_type = opts.event and opts.event.regtype or vim.v.event.regtype
  self.operation = vim.v.event.operator

  self.event = {
    is_visual = self.event_type == "v",
    is_line = string.byte(self.event_type or "") == 86,
    is_visual_block = string.byte(self.event_type or "") == 22,
    is_paste = opts.is_paste,
  }

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

  self.viewport = {
    start_line = vim.fn.line("w0") - 1,
    end_line = vim.fn.line("w$"),
  }

  return self
end

---Checks if a line is within the current viewport
---@param self TextAnimation Animation instance
---@param line number Line number to check
---@return boolean Whether the line is visible
local function is_in_viewport(self, line)
  return line >= self.viewport.start_line and line <= self.viewport.end_line
end

---Computes line configurations for the animation
---@param self TextAnimation Animation instance
---@param animation_progress number Current progress (0 to 1)
---@return table[] Line configurations
local function compute_lines_range(self, animation_progress)
  local lines = {}

  local more_than_one_line = self.animation.range.start_line ~= self.animation.range.end_line

  for i = self.animation.range.start_line, self.animation.range.end_line do
    if is_in_viewport(self, i) then
      local count = MAX_END_COL
      local start_position = self.animation.range.start_col

      if self.event.is_visual_block then
        start_position = self.animation.range.start_col
        count = self.animation.range.end_col - self.animation.range.start_col
      else
        if i == self.animation.range.start_line then
          -- First line
          start_position = self.animation.range.start_col
          count = self.animation.range.end_col - self.animation.range.start_col
          if count == 0 or more_than_one_line then
            count = MAX_END_COL
          end
        elseif i > self.animation.range.start_line and i < self.animation.range.end_line then
          -- Middle lines
          start_position = 0
          count = MAX_END_COL
        else
          -- Last line
          start_position = 0
          count = self.animation.range.end_col
        end
      end

      table.insert(lines, {
        line_number = i,
        start_position = start_position,
        count = math.ceil(count * animation_progress),
      })
    end
  end

  return lines
end

---Renders one line of the animation effect
---@param self TextAnimation Animation instance
---@param line table Line configuration
local function apply_hl(self, line)
  local line_index = line.line_number
  local hl_group = self.animation:get_hl_group()

  if self.cursor_line_enabled then
    local cursor_position = vim.api.nvim_win_get_cursor(0)
    if cursor_position[1] - 1 == line_index then
      hl_group = self.animation:get_overwrite_hl_group()
    end
  end

  utils.set_extmark(line_index, namespace, line.start_position, {
    id = self.animation:get_reserved_id(),
    virt_text_pos = "overlay",
    end_col = line.start_position + line.count,
    hl_group = hl_group,
    hl_mode = "blend",
    priority = self.virtual_text_priority,
  }, self.buffer)
end

---Starts the text animation
---@param refresh_interval_ms number Refresh interval in milliseconds
---@param on_complete function Callback function when animation is complete
function TextAnimation:start(refresh_interval_ms, on_complete)
  local length = self.animation.range.end_col - self.animation.range.start_col
  local buf = self.buffer

  self.animation:start(refresh_interval_ms, length, {
    on_update = function(update_progress)
      -- Only update if buffer is still valid
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      
      -- Clear previous animation state
      vim.api.nvim_buf_clear_namespace(
        buf,
        namespace,
        self.animation.range.start_line,
        self.animation.range.end_line + 1
      )

      -- Apply new animation state
      local lines_range = compute_lines_range(self, update_progress)
      for _, line_range in ipairs(lines_range) do
        apply_hl(self, line_range)
      end
    end,
    on_complete = on_complete,
  })
end

---Stops the text animation
function TextAnimation:stop()
  self.animation:stop()
end

return TextAnimation

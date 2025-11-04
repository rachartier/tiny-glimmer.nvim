---@class AnimationFactorySettings
---@field virtual_text_priority number The priority of the virtual text

---@class AnimationFactory
---@field settings AnimationFactorySettings
---@field effect_pool table {string: table}
---@field animation_refresh number The refresh rate of the animation (in ms)
---@field instance AnimationFactory
---@field buffers table {number: {animations: table, named_animations: table}}

---@class AnimationType
---@field name string
---@field settings table

---@class CreateAnimationOpts
---@field range table {start_line: number, start_col: number, end_line: number, end_col: number}
---@field content string[]|nil Content of the animation

local AnimationFactory = {}
AnimationFactory.__index = AnimationFactory

--- Validation and initialization helpers
local function validate_animation_type(effect_pool, animation_name)
  if not effect_pool[animation_name] then
    error(string.format("Invalid animation type: %s", animation_name))
  end
end

local function merge_settings(base_settings, overwrite_settings)
  return vim.tbl_extend("force", base_settings, overwrite_settings or {})
end

--- Initialize the AnimationFactory singleton
--- @param opts? AnimationFactorySettings Configuration options
--- @param effect_pool? table Animation effect types
--- @param animation_refresh? number Animation refresh rate in ms
function AnimationFactory.initialize(opts, effect_pool, animation_refresh)
  if AnimationFactory.instance then
    return AnimationFactory.instance
  end

  AnimationFactory.instance = setmetatable({
    settings = opts or {},
    effect_pool = effect_pool or {},
    animation_refresh = animation_refresh or 1,
    buffers = {},
  }, AnimationFactory)

  return AnimationFactory.instance
end

--- Get the AnimationFactory singleton instance
--- @return AnimationFactory
function AnimationFactory.get_instance()
  if not AnimationFactory.instance then
    error("TinyGlimmer: AnimationFactory not initialized")
  end
  return AnimationFactory.instance
end

--- Prepare animation configuration
--- @param buffer number Neovim buffer handle
--- @param animation_type string|AnimationType Animation type details
--- @param opts table Animation creation options
--- @return table Prepared animation effect
function AnimationFactory:_prepare_animation_effect(buffer, animation_type, opts)
  if not opts.base.range then
    error("TinyGlimmer: Range is required in options")
  end

  self.buffers[buffer] = self.buffers[buffer] or { animations = {}, named_animations = {} }

  local animation_name = type(animation_type) == "table" and animation_type.name or animation_type

  validate_animation_type(self.effect_pool, animation_name)

  local effect = vim.deepcopy(self.effect_pool[animation_name])
  effect.settings = merge_settings(
    effect.settings,
    type(animation_type) == "table" and animation_type.settings or {}
  )

  return effect
end

--- Manage animation lifecycle in a buffer
--- @param animation_obj table Animation object
--- @param buffer number Neovim buffer handle
--- @param on_complete? function Optional callback when animation completes
function AnimationFactory:_manage_animation(animation_obj, buffer, on_complete)
  if not animation_obj then
    error("TinyGlimmer: Failed to create animation")
  end

  local animation = animation_obj.animation
  local line_key = animation.range.start_line

  -- Stop any existing animation on this line
  if self.buffers[buffer].animations[line_key] then
    self.buffers[buffer].animations[line_key]:stop()
  end

  -- Start new animation
  self.buffers[buffer].animations[line_key] = animation_obj
  animation_obj:start(self.animation_refresh, function()
    self.buffers[buffer].animations[line_key] = nil
    if on_complete then
      on_complete()
    end
  end)
end

--- Manage animation lifecycle in a buffer
--- @param animation_obj table Animation object
--- @param buffer number Neovim buffer handle
--- @param on_complete? function Optional callback when animation completes
function AnimationFactory:_manage_named_animation(name, animation_obj, buffer, on_complete)
  if not animation_obj then
    error("TinyGlimmer: Failed to create animation")
  end

  -- Stop any existing animation on this line
  if self.buffers[buffer].named_animations[name] then
    self.buffers[buffer].named_animations[name]:stop()
  end

  -- Start new animation
  self.buffers[buffer].named_animations[name] = animation_obj
  animation_obj:start(self.animation_refresh, function()
    self.buffers[buffer].named_animations[name] = nil
    if on_complete then
      on_complete()
    end
  end)
end

--- Create and launch a text animation
--- @param animation_type string|AnimationType Animation type
--- @param opts CreateAnimationOpts Animation options
function AnimationFactory:create_text_animation(animation_type, opts)
  local buffer = vim.api.nvim_get_current_buf()
  local effect = self:_prepare_animation_effect(buffer, animation_type, opts)
  local animation = require("tiny-glimmer.animation.premade.text").new(effect, opts)
  self:_manage_animation(animation, buffer, opts.on_complete)
end

--- Create and launch a named text animation
--- @param name string Animation name
--- @param animation_type string|AnimationType Animation type
--- @param opts CreateAnimationOpts Animation options
function AnimationFactory:create_named_text_animation(name, animation_type, opts)
  local buffer = vim.api.nvim_get_current_buf()
  local effect = self:_prepare_animation_effect(buffer, animation_type, opts)
  local animation = require("tiny-glimmer.animation.premade.text").new(effect, opts)
  self:_manage_named_animation(name, animation, buffer, opts.on_complete)
end

--- Create and launch a line animation
--- @param animation_type string|AnimationType Animation type
--- @param opts CreateAnimationOpts Animation options
function AnimationFactory:create_line_animation(animation_type, opts)
  local buffer = vim.api.nvim_get_current_buf()
  local effect = self:_prepare_animation_effect(buffer, animation_type, opts)
  local animation = require("tiny-glimmer.animation.premade.line").new(effect, opts)
  self:_manage_animation(animation, buffer, opts.on_complete)
end

return AnimationFactory

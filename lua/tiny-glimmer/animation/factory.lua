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

--- Normalize animation_type to table format
---@param anim_type string|AnimationType Animation type (string or table)
---@return AnimationType Normalized animation type table
local function normalize_animation_type(anim_type)
  if type(anim_type) == "string" then
    return { name = anim_type, settings = {} }
  end
  return anim_type
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
  if not opts.base.range and not opts.base.ranges then
    error("TinyGlimmer: Range or ranges is required in options")
  end

  self.buffers[buffer] = self.buffers[buffer] or {}
  self.buffers[buffer].animations = self.buffers[buffer].animations or {}
  self.buffers[buffer].named_animations = self.buffers[buffer].named_animations or {}

  local anim_type = normalize_animation_type(animation_type)
  validate_animation_type(self.effect_pool, anim_type.name)

  local effect = vim.deepcopy(self.effect_pool[anim_type.name])
  effect.settings = merge_settings(effect.settings, anim_type.settings)

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
  if not animation then
    error("TinyGlimmer: Invalid animation object - missing animation")
  end

  -- Support both single range and multi-range
  local range_to_check = animation.range or (animation.ranges and animation.ranges[1])
  if not range_to_check or not range_to_check.start_line then
    error("TinyGlimmer: Invalid animation object - missing range or start_line")
  end

  self:_register_animation(
    "animations",
    range_to_check.start_line,
    animation_obj,
    buffer,
    on_complete
  )
end

--- Manage named animation lifecycle in a buffer
--- @param name string Animation name
--- @param animation_obj table Animation object
--- @param buffer number Neovim buffer handle
--- @param on_complete? function Optional callback when animation completes
function AnimationFactory:_manage_named_animation(name, animation_obj, buffer, on_complete)
  if not animation_obj then
    error("TinyGlimmer: Failed to create animation")
  end

  self:_register_animation("named_animations", name, animation_obj, buffer, on_complete)
end

--- Store an animation under a key, stopping any previous one, and start it
--- @param collection string "animations" or "named_animations"
--- @param key string|number Line number or animation name
function AnimationFactory:_register_animation(collection, key, animation_obj, buffer, on_complete)
  if not self.buffers[buffer] then
    self.buffers[buffer] = { animations = {}, named_animations = {} }
  end
  self.buffers[buffer][collection] = self.buffers[buffer][collection] or {}
  local animations = self.buffers[buffer][collection]

  if animations[key] then
    animations[key]:stop()
  end

  animations[key] = animation_obj
  animation_obj:start(self.animation_refresh, function()
    local buf_data = self.buffers[buffer]
    if buf_data and buf_data[collection] then
      buf_data[collection][key] = nil
    end
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

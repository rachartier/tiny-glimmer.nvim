local M = {}

local get_config = function()
  return require("tiny-glimmer").config
end

--- Disable the animation
function M.disable()
  local config = get_config()
  config.enabled = false
end

--- Enable the animation
function M.enable()
  local config = get_config()
  config.enabled = true
end

--- Toggle the plugin on or off
function M.toggle()
  local config = get_config()
  config.enabled = not config.enabled
end

--- Change highlight colors for animation(s)
--- @param animation_name string|string[]|"all" Animation name(s) to modify
--- @param hl table Highlight configuration { from_color = ..., to_color = ... }
function M.change_hl(animation_name, hl)
  local config = get_config()
  local highlights = require("tiny-glimmer.config.highlights")

  local function change_animation_hl(animation, hl_config)
    if hl_config.from_color then
      animation.from_color = hl_config.from_color
    end
    if hl_config.to_color then
      animation.to_color = hl_config.to_color
    end
  end

  if animation_name == "all" then
    for _, animation in pairs(config.animations) do
      change_animation_hl(animation, hl)
    end
    local glimmer = require("tiny-glimmer")
    glimmer.config = highlights.sanitize_highlights(config)
    return
  end

  if type(animation_name) == "table" then
    for _, name in ipairs(animation_name) do
      if config.animations[name] then
        change_animation_hl(config.animations[name], hl)
      else
        vim.notify("TinyGlimmer: Animation " .. name .. " not found. Skipping", vim.log.levels.WARN)
      end
    end
    local glimmer = require("tiny-glimmer")
    glimmer.config = highlights.sanitize_highlights(config)
    return
  end

  if not config.animations[animation_name] then
    vim.notify("TinyGlimmer: Animation " .. animation_name .. " not found", vim.log.levels.ERROR)
    return
  end

  local animation = config.animations[animation_name]
  change_animation_hl(animation, hl)
  config.animations[animation_name] = animation
  local glimmer = require("tiny-glimmer")
  glimmer.config = highlights.sanitize_highlights(config)
end

--- Get the background highlight color for the given highlight name
--- @param hl_name string
--- @return string Hex color
function M.get_background_hl(hl_name)
  local utils = require("tiny-glimmer.utils")
  return utils.int_to_hex(utils.get_highlight(hl_name).bg)
end

--- Search navigation methods
function M.search_next()
  local config = get_config()
  if not config.overwrite.search.enabled then
    vim.notify(
      'TinyGlimmer: Search is not enabled in your configuration.\nYou should not use require("tiny-glimmer").search_next().',
      vim.log.levels.WARN
    )
    return
  end
  require("tiny-glimmer.overwrite.search").search_next(config.overwrite.search)
end

function M.search_prev()
  local config = get_config()
  if not config.overwrite.search.enabled then
    vim.notify(
      'TinyGlimmer: Search is not enabled in your configuration.\nYou should not use require("tiny-glimmer").search_prev().',
      vim.log.levels.WARN
    )
    return
  end
  require("tiny-glimmer.overwrite.search").search_prev(config.overwrite.search)
end

function M.search_under_cursor()
  local config = get_config()
  if not config.overwrite.search.enabled then
    vim.notify(
      'TinyGlimmer: Search is not enabled in your configuration.\nYou should not use require("tiny-glimmer").search_under_cursor().',
      vim.log.levels.WARN
    )
    return
  end
  require("tiny-glimmer.overwrite.search").search_under_cursor(config.overwrite.search)
end

--- Paste methods
function M.paste()
  local config = get_config()
  if not config.overwrite.paste.enabled then
    vim.notify(
      'TinyGlimmer: Paste is not enabled in your configuration.\nYou should not use require("tiny-glimmer").paste().',
      vim.log.levels.WARN
    )
    return
  end
  require("tiny-glimmer.overwrite.paste").paste(config.overwrite.paste)
end

function M.Paste()
  local config = get_config()
  if not config.overwrite.paste.enabled then
    vim.notify(
      'TinyGlimmer: Paste is not enabled in your configuration.\nYou should not use require("tiny-glimmer").Paste().',
      vim.log.levels.WARN
    )
    return
  end
  require("tiny-glimmer.overwrite.paste").Paste(config.overwrite.paste)
end

--- Undo/Redo methods
function M.undo()
  local config = get_config()
  if not config.overwrite.undo.enabled then
    vim.notify(
      'TinyGlimmer: Undo is not enabled in your configuration.\nYou should not use require("tiny-glimmer").undo().',
      vim.log.levels.WARN
    )
    return
  end
  require("tiny-glimmer.overwrite.undo").undo(config.overwrite.undo)
end

function M.redo()
  local config = get_config()
  if not config.overwrite.redo.enabled then
    vim.notify(
      'TinyGlimmer: Redo is not enabled in your configuration.\nYou should not use require("tiny-glimmer").redo().',
      vim.log.levels.WARN
    )
    return
  end
  require("tiny-glimmer.overwrite.undo").redo(config.overwrite.redo)
end

--- Refresh highlights after theme change
function M.apply()
  local glimmer = require("tiny-glimmer")
  local setup = require("tiny-glimmer.setup")
  local AnimationFactory = require("tiny-glimmer.animation.factory")

  -- Re-prepare config with fresh highlight values
  local config = setup.prepare_config(glimmer.user_config)

  -- Update effects pool
  local effects_pool = require("tiny-glimmer.premade_effects")
  local Effect = require("tiny-glimmer.animation.effect")
  for name, effect_settings in pairs(config.animations) do
    if effects_pool[name] then
      effects_pool[name]:update_settings(effect_settings)
    else
      effects_pool[name] = Effect.new(effect_settings, effect_settings.effect)
    end
  end

  -- Re-initialize animation factory
  AnimationFactory.initialize(config, effects_pool, config.refresh_interval_ms)

  glimmer.config = config
end

return M

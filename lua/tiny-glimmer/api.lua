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

--- Build a function that runs an overwrite module function, warning if its section is disabled
--- @param section string Key in config.overwrite
--- @param module string Module name under tiny-glimmer.overwrite
--- @param fn_name string Function name in the module (also the public API name)
local function guarded(section, module, fn_name)
  return function()
    local config = get_config()
    if not config.overwrite[section].enabled then
      vim.notify(
        string.format(
          'TinyGlimmer: %s is not enabled in your configuration.\nYou should not use require("tiny-glimmer").%s().',
          section:gsub("^%l", string.upper),
          fn_name
        ),
        vim.log.levels.WARN
      )
      return
    end
    require("tiny-glimmer.overwrite." .. module)[fn_name](config.overwrite[section])
  end
end

M.search_next = guarded("search", "search", "search_next")
M.search_prev = guarded("search", "search", "search_prev")
M.search_under_cursor = guarded("search", "search", "search_under_cursor")
M.paste = guarded("paste", "paste", "paste")
M.Paste = guarded("paste", "paste", "Paste")
M.undo = guarded("undo", "undo", "undo")
M.redo = guarded("redo", "undo", "redo")

--- Refresh highlights after theme change
function M.apply()
  local glimmer = require("tiny-glimmer")
  local setup = require("tiny-glimmer.setup")
  local AnimationFactory = require("tiny-glimmer.animation.factory")

  -- Re-prepare config with fresh highlight values
  local config = setup.prepare_config(glimmer.user_config)

  local effects_pool = setup.update_effects_pool(config)

  -- Re-initialize animation factory
  AnimationFactory.initialize(config, effects_pool, config.refresh_interval_ms)

  glimmer.config = config
end

return M

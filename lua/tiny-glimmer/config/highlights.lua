local utils = require("tiny-glimmer.utils")

local M = {}

local hl_visual_bg = utils.int_to_hex(utils.get_highlight("Visual").bg)
local hl_normal_bg = utils.int_to_hex(utils.get_highlight("Normal").bg)

--- Process a single highlight color reference
--- @param color string|nil Hex color or highlight group name
--- @param highlight_name string Animation name (for warning messages)
--- @param is_from_color boolean True if this is a from_color, false if to_color
--- @param options table Options containing transparency_color and disable_warnings
--- @return string Processed hex color
function M.process_highlight_color(color, highlight_name, is_from_color, options)
  if not color or color:sub(1, 1) == "#" then
    return color
  end

  local converted_color = utils.int_to_hex(utils.get_highlight(color).bg)

  if converted_color:lower() == "none" then
    if options.transparency_color then
      return options.transparency_color
    end

    local is_transparent = utils.get_highlight("Normal").bg == nil
      or utils.get_highlight("Normal").bg == "None"

    if not is_transparent then
      local default_highlight = is_from_color and "Visual" or "Normal"
      if not options.disable_warnings then
        local msg = string.format(
          "TinyGlimmer: %s_color is set to None for %s animation\nDefaulting to %s highlight",
          is_from_color and "from" or "to",
          highlight_name,
          default_highlight
        )
        vim.notify(msg, vim.log.levels.WARN)
      end
      return is_from_color and hl_visual_bg or hl_normal_bg
    end
    return "#000000"
  end

  return converted_color
end

--- Process animation colors for table-based animation config
local function process_animation_colors(animation, name, options)
  if type(animation) == "table" then
    animation.settings.from_color =
      M.process_highlight_color(animation.settings.from_color, name, true, options)
    animation.settings.to_color =
      M.process_highlight_color(animation.settings.to_color, name, false, options)
  end
end

--- Validate transparency configuration
function M.validate_transparency(options)
  local normal_bg = utils.get_highlight("Normal").bg
  local is_transparent = normal_bg == nil or normal_bg == "None"

  if is_transparent and not options.transparency_color and not options.disable_warnings then
    vim.notify(
      "TinyGlimmer: Normal highlight group has a transparent background.\n"
        .. "Please set the transparency_color option to a valid color",
      vim.log.levels.WARN
    )
  end
end

--- Sanitize all highlights in configuration
--- @param options table Full plugin configuration
function M.sanitize_highlights(options)
  M.validate_transparency(options)

  -- Process animation colors
  for name, highlight in pairs(options.animations) do
    highlight.from_color = M.process_highlight_color(highlight.from_color, name, true, options)
    highlight.to_color = M.process_highlight_color(highlight.to_color, name, false, options)
  end

  -- Process preset colors
  for name, preset in pairs(options.presets) do
    if preset.default_animation then
      if type(preset.default_animation) == "table" then
        process_animation_colors(preset.default_animation, name, options)
      end
    end
  end

  -- Process overwrite and support colors
  for _, category in ipairs({ options.overwrite, options.support }) do
    for name, preset in pairs(category) do
      if type(preset) == "table" and preset.default_animation then
        process_animation_colors(preset.default_animation, name, options)
      end
    end
  end
end

return M

local utils = require("tiny-glimmer.utils")

local M = {}

--- Get default fallback color for transparent backgrounds
local function get_fallback_color(is_from_color)
  local highlight_name = is_from_color and "Visual" or "Normal"
  return utils.int_to_hex(utils.get_highlight(highlight_name).bg)
end

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
      if not options.disable_warnings then
        local default_hl = is_from_color and "Visual" or "Normal"
        vim.notify(
          string.format(
            "TinyGlimmer: %s_color is set to None for %s animation\nDefaulting to %s highlight",
            is_from_color and "from" or "to",
            highlight_name,
            default_hl
          ),
          vim.log.levels.WARN
        )
      end
      return get_fallback_color(is_from_color)
    end
    return "#000000"
  end

  return converted_color
end

--- Process animation colors for table-based animation config
local function process_animation_colors(animation, name, options)
  if type(animation) ~= "table" then
    return animation
  end

  local new_animation = vim.deepcopy(animation)
  new_animation.settings.from_color =
    M.process_highlight_color(new_animation.settings.from_color, name, true, options)
  new_animation.settings.to_color =
    M.process_highlight_color(new_animation.settings.to_color, name, false, options)
  return new_animation
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
--- @return table New configuration with sanitized highlights
function M.sanitize_highlights(options)
  M.validate_transparency(options)

  local sanitized = vim.deepcopy(options)

  -- Process animation colors
  for name, highlight in pairs(sanitized.animations) do
    highlight.from_color = M.process_highlight_color(highlight.from_color, name, true, sanitized)
    highlight.to_color = M.process_highlight_color(highlight.to_color, name, false, sanitized)
  end

  -- Process preset, overwrite, and support colors
  for _, category in ipairs({ sanitized.presets, sanitized.overwrite, sanitized.support }) do
    for name, preset in pairs(category) do
      if type(preset) == "table" and preset.default_animation and type(preset.default_animation) == "table" then
        preset.default_animation = process_animation_colors(preset.default_animation, name, sanitized)
      end
    end
  end

  return sanitized
end

return M

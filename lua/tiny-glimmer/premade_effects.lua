local easing_functions = require("tiny-glimmer.animation.easing")
local utils = require("tiny-glimmer.utils")

local function rgb_builder(self)
  return {
    initial = utils.hex_to_rgb(self.settings.from_color),
    final = utils.hex_to_rgb(self.settings.to_color),
  }
end

--- Interpolate from one RGB color to another with an easing function
local function eased_rgb(from, to, progress, ease)
  local fn = easing_functions[ease] or easing_functions.linear

  return utils.rgb_to_hex({
    r = utils.clamp(fn(progress, from.r, to.r - from.r, 1), 0, 255),
    g = utils.clamp(fn(progress, from.g, to.g - from.g, 1), 0, 255),
    b = utils.clamp(fn(progress, from.b, to.b - from.b, 1), 0, 255),
  })
end

local function make_effect(update_fn, builder)
  return {
    settings = {},
    builder = builder,
    build_starter = function(self)
      if self.builder then
        self.starter = self.builder(self)
      end
    end,
    update_settings = function(self, settings)
      self.settings = settings
    end,
    update_fn = update_fn,
  }
end

local rainbow_colors = {
  { r = 255, g = 0, b = 0 },
  { r = 255, g = 127, b = 0 },
  { r = 255, g = 255, b = 0 },
  { r = 0, g = 255, b = 0 },
  { r = 0, g = 0, b = 255 },
  { r = 75, g = 0, b = 130 },
  { r = 148, g = 0, b = 211 },
}

return {
  fade = make_effect(function(self, progress, ease)
    return eased_rgb(self.starter.initial, self.starter.final, progress, ease), 1
  end, rgb_builder),

  reverse_fade = make_effect(function(self, progress, ease)
    return eased_rgb(self.starter.final, self.starter.initial, progress, ease), 1
  end, rgb_builder),

  bounce = make_effect(function(self, progress)
    local oscillation = math.abs(math.sin(progress * math.pi * self.settings.oscillation_count))
    local initial = self.starter.initial
    local final = self.starter.final

    local current = {
      r = math.max(initial.r + (final.r - initial.r) * oscillation, 0),
      g = math.max(initial.g + (final.g - initial.g) * oscillation, 0),
      b = math.max(initial.b + (final.b - initial.b) * oscillation, 0),
    }

    return utils.rgb_to_hex(current), 1
  end, rgb_builder),

  left_to_right = make_effect(function(self, progress, ease)
    local p = utils.clamp(progress, self.starter.min_progress, 1)

    return eased_rgb(
      self.starter.initial,
      self.starter.final,
      math.min(p, self.starter.max_progress),
      ease
    ),
      progress
  end, function(self)
    local starter = rgb_builder(self)
    starter.min_progress = self.settings.min_progress or 0
    starter.max_progress = self.settings.max_progress or 1
    return starter
  end),

  pulse = make_effect(function(self, progress)
    local initial = self.starter.initial
    local final = self.starter.final

    local pulse = math.abs(math.sin(progress * math.pi * self.settings.pulse_count))
    pulse = pulse * self.settings.intensity

    local current = {
      r = math.min(255, initial.r + (final.r - initial.r) * progress + pulse * 50),
      g = math.min(255, initial.g + (final.g - initial.g) * progress + pulse * 50),
      b = math.min(255, initial.b + (final.b - initial.b) * progress + pulse * 50),
    }

    return utils.rgb_to_hex(current), 1
  end, rgb_builder),

  rainbow = make_effect(function(_, progress)
    local index = math.floor(progress * (#rainbow_colors - 1)) + 1
    local next_index = math.min(index + 1, #rainbow_colors)
    local color_progress = (progress * (#rainbow_colors - 1)) % 1

    local current = {
      r = rainbow_colors[index].r
        + (rainbow_colors[next_index].r - rainbow_colors[index].r) * color_progress,
      g = rainbow_colors[index].g
        + (rainbow_colors[next_index].g - rainbow_colors[index].g) * color_progress,
      b = rainbow_colors[index].b
        + (rainbow_colors[next_index].b - rainbow_colors[index].b) * color_progress,
    }

    return utils.rgb_to_hex(current), 1
  end),
}

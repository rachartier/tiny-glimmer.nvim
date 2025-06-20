local Effect = require("tiny-glimmer.animation.effect")
local easing_functions = require("tiny-glimmer.animation.easing")
local utils = require("tiny-glimmer.utils")

local function create_effect(opts)
  return Effect.new({}, opts.update_fn, opts.builder)
end

return {
  fade = create_effect({
    builder = function(self)
      return {
        initial = utils.hex_to_rgb(self.settings.from_color),
        final = utils.hex_to_rgb(self.settings.to_color),
      }
    end,
    update_fn = function(self, progress, ease)
      local initial = self.starter.initial
      local final = self.starter.final
      local current = {}

      local fn = easing_functions[ease]

      current = {
        r = utils.clamp(fn(progress, initial.r, final.r - initial.r, 1), 0, 255),
        g = utils.clamp(fn(progress, initial.g, final.g - initial.g, 1), 0, 255),
        b = utils.clamp(fn(progress, initial.b, final.b - initial.b, 1), 0, 255),
      }

      return utils.rgb_to_hex(current), 1
    end,
  }),
  reverse_fade = create_effect({
    builder = function(self)
      return {
        initial = utils.hex_to_rgb(self.settings.from_color),
        final = utils.hex_to_rgb(self.settings.to_color),
      }
    end,
    update_fn = function(self, progress, ease)
      local initial = self.starter.initial
      local final = self.starter.final

      local fn = easing_functions[ease]

      local current = {
        r = utils.clamp(fn(progress, final.r, initial.r - final.r, 1), 0, 255),
        g = utils.clamp(fn(progress, final.g, initial.g - final.g, 1), 0, 255),
        b = utils.clamp(fn(progress, final.b, initial.b - final.b, 1), 0, 255),
      }

      return utils.rgb_to_hex(current), 1
    end,
  }),
  bounce = create_effect({
    builder = function(self)
      return {
        initial = utils.hex_to_rgb(self.settings.from_color),
        final = utils.hex_to_rgb(self.settings.to_color),
      }
    end,
    update_fn = function(self, progress)
      local oscillation = math.abs(math.sin(progress * math.pi * self.settings.oscillation_count))
      local initial = self.starter.initial
      local final = self.starter.final

      local current = {
        r = math.max(initial.r + (final.r - initial.r) * oscillation, 0),
        g = math.max(initial.g + (final.g - initial.g) * oscillation, 0),
        b = math.max(initial.b + (final.b - initial.b) * oscillation, 0),
      }

      return utils.rgb_to_hex(current), 1
    end,
  }),
  left_to_right = create_effect({
    builder = function(self)
      return {
        initial = utils.hex_to_rgb(self.settings.from_color),
        final = utils.hex_to_rgb(self.settings.to_color),
        min_progress = self.settings.min_progress or 0,
        max_progress = self.settings.max_progress or 1,
      }
    end,
    update_fn = function(self, progress, ease)
      local initial = self.starter.initial
      local final = self.starter.final
      local fn = easing_functions[ease] or easing_functions.linear

      local p = utils.clamp(progress, self.starter.min_progress, 1)

      local current = {
        r = utils.clamp(
          fn(math.min(p, self.starter.max_progress), initial.r, final.r - initial.r, 1),
          0,
          255
        ),
        g = utils.clamp(
          fn(math.min(p, self.starter.max_progress), initial.g, final.g - initial.g, 1),
          0,
          255
        ),
        b = utils.clamp(
          fn(math.min(p, self.starter.max_progress), initial.b, final.b - initial.b, 1),
          0,
          255
        ),
      }

      return utils.rgb_to_hex(current), progress
    end,
  }),
  pulse = create_effect({
    builder = function(self)
      return {
        initial = utils.hex_to_rgb(self.settings.from_color),
        final = utils.hex_to_rgb(self.settings.to_color),
      }
    end,
    update_fn = function(self, progress)
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
    end,
  }),
  rainbow = create_effect({
    update_fn = function(self, progress)
      local rainbow_colors = {
        { r = 255, g = 0, b = 0 },
        { r = 255, g = 127, b = 0 },
        { r = 255, g = 255, b = 0 },
        { r = 0, g = 255, b = 0 },
        { r = 0, g = 0, b = 255 },
        { r = 75, g = 0, b = 130 },
        { r = 148, g = 0, b = 211 },
      }

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
    end,
  }),
}

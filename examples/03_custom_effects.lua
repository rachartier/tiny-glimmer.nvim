-- Custom Effect Examples
-- Demonstrates creating custom animation effects using create_effect()
-- These are runtime effects not registered with the factory

local glimmer = require("tiny-glimmer.lib")

-- Simple color fade from red to blue
-- Linear interpolation between two colors over time
local simple_fade = glimmer.create_effect({
  settings = {
    max_duration = 1000,
    chars_for_max_duration = 20,
    start_color = { r = 255, g = 0, b = 0 },
    end_color = { r = 0, g = 0, b = 255 },
  },
  update_fn = function(self, progress, ease)
    local start = self.settings.start_color
    local finish = self.settings.end_color
    local r = math.floor(start.r + (finish.r - start.r) * progress)
    local g = math.floor(start.g + (finish.g - start.g) * progress)
    local b = math.floor(start.b + (finish.b - start.b) * progress)
    return string.format("#%02x%02x%02x", r, g, b), progress
  end,
})

-- Breathing effect using sine wave oscillation
-- Creates smooth pulsing brightness animation
local breathing_effect = glimmer.create_effect({
  settings = {
    max_duration = 2000,
    chars_for_max_duration = 20,
    base_color = "#4EC9B0",
  },
  update_fn = function(self, progress, ease)
    local oscillation = (math.sin(progress * math.pi * 2) + 1) / 2
    local brightness = math.floor(oscillation * 255)
    local color = string.format("#%02x%02x%02x", brightness, brightness, brightness)
    return color, progress
  end,
})

-- Wave effect that propagates across text
-- Uses builder to initialize state, intensity based on distance from wave center
local wave_effect = glimmer.create_effect({
  settings = {
    max_duration = 1000,
    chars_for_max_duration = 30,
    wave_color = "#FF6B6B",
  },
  builder = function(self)
    return { wave_width = 0.2 }
  end,
  update_fn = function(self, progress, ease)
    local wave_pos = progress
    local wave_width = self.starter.wave_width
    local intensity = 0
    if progress >= wave_pos - wave_width and progress <= wave_pos + wave_width then
      local distance = math.abs(progress - wave_pos) / wave_width
      intensity = 1 - distance
    end
    local r = math.floor(255 * intensity)
    local g = math.floor(107 * intensity)
    local b = math.floor(107 * intensity)
    return string.format("#%02x%02x%02x", r, g, b), progress
  end,
})

-- Multi-color gradient through red -> yellow -> green -> blue
-- Segments progress across color stops
local gradient_effect = glimmer.create_effect({
  settings = {
    max_duration = 800,
    chars_for_max_duration = 20,
    colors = {
      { r = 255, g = 0, b = 0 },
      { r = 255, g = 255, b = 0 },
      { r = 0, g = 255, b = 0 },
      { r = 0, g = 0, b = 255 },
    },
  },
  update_fn = function(self, progress, ease)
    local colors = self.settings.colors
    local segment_count = #colors - 1
    local segment = math.floor(progress * segment_count)
    segment = math.min(segment, segment_count - 1)
    local local_progress = (progress * segment_count) - segment
    local start = colors[segment + 1]
    local finish = colors[segment + 2]
    local r = math.floor(start.r + (finish.r - start.r) * local_progress)
    local g = math.floor(start.g + (finish.g - start.g) * local_progress)
    local b = math.floor(start.b + (finish.b - start.b) * local_progress)
    return string.format("#%02x%02x%02x", r, g, b), progress
  end,
})

-- Sparkle effect with pseudo-random intensity variations
-- Builder generates seed for randomization
local sparkle_effect = glimmer.create_effect({
  settings = {
    max_duration = 1500,
    chars_for_max_duration = 25,
    base_color = { r = 255, g = 215, b = 0 },
  },
  builder = function(self)
    math.randomseed(os.time())
    return { seed = math.random(1, 1000) }
  end,
  update_fn = function(self, progress, ease)
    local base = self.settings.base_color
    local sparkle = ((progress * 1000 + self.starter.seed) % 10) / 10
    local intensity = 0.5 + sparkle * 0.5
    local r = math.floor(base.r * intensity)
    local g = math.floor(base.g * intensity)
    local b = math.floor(base.b * intensity)
    return string.format("#%02x%02x%02x", r, g, b), progress
  end,
})

-- Note: These effects are created but not registered with the factory
-- To register them globally, see examples/06_factory_integration.lua

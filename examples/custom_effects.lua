-- Example 6: Custom effect creation
-- Build your own animation effects from scratch

local glimmer = require("tiny-glimmer.lib")

-- Example 1: Breathing effect (oscillating opacity)
local breathing_effect = glimmer.create_effect({
  settings = {
    max_duration = 2000,
    chars_for_max_duration = 20,
    base_color = "#4EC9B0",
  },
  update_fn = function(self, progress, ease)
    -- Create a breathing pattern using sine wave
    local oscillation = (math.sin(progress * math.pi * 2) + 1) / 2

    -- Interpolate brightness
    local brightness = math.floor(oscillation * 255)
    local color = string.format("#%02x%02x%02x", brightness, brightness, brightness)

    return color, progress
  end,
})

-- Example 2: Wave effect (color propagates from left to right)
local wave_effect = glimmer.create_effect({
  settings = {
    max_duration = 1000,
    chars_for_max_duration = 30,
    wave_color = "#FF6B6B",
  },
  builder = function(self)
    -- Initialize wave data
    return {
      wave_position = 0,
      wave_width = 0.2,
    }
  end,
  update_fn = function(self, progress, ease)
    -- Move wave from left to right
    local wave_pos = progress
    local wave_width = self.starter.wave_width

    -- Only show color in the wave region
    local intensity = 0
    if progress >= wave_pos - wave_width and progress <= wave_pos + wave_width then
      local distance = math.abs(progress - wave_pos) / wave_width
      intensity = 1 - distance
    end

    local r = math.floor(255 * intensity)
    local g = math.floor(107 * intensity)
    local b = math.floor(107 * intensity)

    local color = string.format("#%02x%02x%02x", r, g, b)
    return color, progress
  end,
})

-- Example 3: Gradient effect
local gradient_effect = glimmer.create_effect({
  settings = {
    max_duration = 500,
    chars_for_max_duration = 20,
    start_color = { r = 255, g = 0, b = 0 },
    end_color = { r = 0, g = 0, b = 255 },
  },
  update_fn = function(self, progress, ease)
    local start = self.settings.start_color
    local finish = self.settings.end_color

    -- Linear interpolation between colors
    local r = math.floor(start.r + (finish.r - start.r) * progress)
    local g = math.floor(start.g + (finish.g - start.g) * progress)
    local b = math.floor(start.b + (finish.b - start.b) * progress)

    local color = string.format("#%02x%02x%02x", r, g, b)
    return color, progress
  end,
})

-- Use the custom effects
vim.keymap.set("n", "<leader>ae1", function()
  -- Note: You would need to register these effects with the factory
  -- This is a simplified example showing the concept
  print("Custom effects created! See the code for implementation details.")
end, { desc = "Custom effect example" })

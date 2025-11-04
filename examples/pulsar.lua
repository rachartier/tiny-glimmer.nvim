-- Example 4: Window focus animation (pulsar-like)
-- Animate the cursor line when switching windows or entering insert mode

local glimmer = require("tiny-glimmer.lib")

-- Configuration
local config = {
  duration = 400,
  from_color = "#3B4252",
  to_color = "Normal",
  effect = "fade",
  easing = "outQuad",
}

-- Create animation group
local group = vim.api.nvim_create_augroup("GlimmerPulsar", { clear = true })

-- Animate on window enter
vim.api.nvim_create_autocmd("WinEnter", {
  group = group,
  callback = function()
    glimmer.create_line_animation({
      range = glimmer.get_line_range(0),
      duration = config.duration,
      from_color = config.from_color,
      to_color = config.to_color,
      effect = config.effect,
      easing = config.easing,
    })
  end,
})

-- Animate on insert enter
vim.api.nvim_create_autocmd("InsertEnter", {
  group = group,
  callback = function()
    glimmer.create_line_animation({
      range = glimmer.get_line_range(0),
      duration = config.duration,
      from_color = "#2E3440",
      to_color = config.to_color,
      effect = config.effect,
      easing = config.easing,
    })
  end,
})

-- Animate on command enter
vim.api.nvim_create_autocmd("CmdlineEnter", {
  group = group,
  callback = function()
    glimmer.create_line_animation({
      range = glimmer.get_line_range(0),
      duration = config.duration,
      from_color = config.from_color,
      to_color = config.to_color,
      effect = config.effect,
      easing = config.easing,
    })
  end,
})

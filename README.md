# 🌟 tiny-glimmer.nvim

A tiny Neovim plugin that adds subtle animations to yank/paste operations.

![Neovim version](https://img.shields.io/badge/Neovim-0.10+-blueviolet.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## ✨ Features


https://github.com/user-attachments/assets/e47ab8d3-33d7-41f4-a44a-c8d327382637


- Smooth animations for yank and paste operations
- Multiple animation styles:
  - `fade`: Simple fade in/out effect
  - `bounce`: Bouncing transition
  - `left_to_right`: Linear left-to-right animation
  - `pulse`: Pulsating highlight effect
  - `rainbow`: Rainbow transition

## 📋 Requirements

- Neovim >= 0.10

## 📦 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
    "rachartier/tiny-glimmer.nvim",
    event = "TextYankPost",
    opts = {
        -- your configuration
    },
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use {
    'rachartier/tiny-glimmer.nvim',
    config = function()
        require('tiny-glimmer').setup()
    end
}
```

## ⚙️ Configuration

Here's the default configuration:
```lua
require('tiny-glimmer').setup({
    enabled = true,
    default_animation = "fade",
    refresh_interval_ms = 6,
    animations = {
        fade = {
            max_duration = 250,
            chars_for_max_duration = 10,
        },
        bounce = {
            max_duration = 500,
            chars_for_max_duration = 20,
            oscillation_count = 1,
        },
        left_to_right = {
            max_duration = 350,
            chars_for_max_duration = 40,
            lingering_time = 50,
        },
        pulse = {
            max_duration = 400,
            chars_for_max_duration = 15,
            pulse_count = 2,
            intensity = 1.2,
        },
        rainbow = {
            max_duration = 600,
            chars_for_max_duration = 20,
        },
    },
    virt_text = {
        priority = 2048,
    },
})
```

### Animation Settings

Each animation type has its own configuration options:

- `max_duration`: Maximum duration of the animation in milliseconds
- `chars_for_max_duration`: Number of characters that will result in max duration
- `lingering_time`: How long the animation stays visible after completion (for applicable animations)
- `oscillation_count`: Number of bounces (for bounce animation)
- `pulse_count`: Number of pulses (for pulse animation)
- `intensity`: Animation intensity multiplier (for pulse animation)

## 🎮 Commands

- `:TinyGlimmer enable` - Enable animations
- `:TinyGlimmer disable` - Disable animations
- `:TinyGlimmer fade` - Switch to fade animation
- `:TinyGlimmer bounce` - Switch to bounce animation
- `:TinyGlimmer left_to_right` - Switch to left-to-right animation
- `:TinyGlimmer pulse` - Switch to pulse animation
- `:TinyGlimmer rainbow` - Switch to rainbow animation

## 🛠️ API

```lua
-- Enable animations
require('tiny-glimmer').enable()

-- Disable animations
require('tiny-glimmer').disable()

-- Toggle animations
require('tiny-glimmer').toggle()
```

## 📝 License

MIT


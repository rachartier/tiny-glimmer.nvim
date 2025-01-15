# 🌟 tiny-glimmer.nvim

A tiny Neovim plugin that adds subtle animations to various operations.

![Neovim version](https://img.shields.io/badge/Neovim-0.10+-blueviolet.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

> [!WARNING]
>This plugin is still in beta. It is possible that some changes will break the plugin.

## ✨ Features

![tiny_glimmer_demo](https://github.com/user-attachments/assets/f662b9d3-98f5-4683-97e4-c74fe98e2f0e)

- Smooth animations for yank operations
- Multiple animation styles:
  - `fade`: Simple fade in/out effect
  - `reverse_fade`: Reverse fade in/out effect
  - `bounce`: Bouncing transition
  - `left_to_right`: Linear left-to-right animation
  - `pulse`: Pulsating highlight effect
  - `rainbow`: Rainbow transition
  - `custom`: Custom animation that you can define

## 📋 Requirements

- Neovim >= 0.10

## 📦 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
    "rachartier/tiny-glimmer.nvim",
    event = "VeryLazy",
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

    overwrite = {
        search = {
            enabled = false,
            default_animation = "pulse",

            --- Keys to navigate to the next match after `n` or `N`
            next_mapping = "zzzv", -- Can be empty or nil
            prev_mapping = "zzzv", -- Can be empty or nil
        },
        paste = {
            enabled = false,
            default_animation = "reverse_fade",
        },
    },


    -- Only use if you have a transparent background
    -- It will override the highlight group background color for `to_color` in all animations
    transparency_color = nil,
    animations = {
        fade = {
            max_duration = 400,
            min_duration = 300,
            easing = "outQuad",
            chars_for_max_duration = 10,
        },
        reverse_fade = {
            max_duration = 380,
            min_duration = 300,
            easing = "outBack",
            chars_for_max_duration = 10,
        },
        bounce = {
            max_duration = 500,
            min_duration = 400,
            chars_for_max_duration = 20,
            oscillation_count = 1,
        },
        left_to_right = {
            max_duration = 350,
            min_duration = 350,
            chars_for_max_duration = 25,
            lingering_time = 50,
        },
        pulse = {
            max_duration = 600,
            min_duration = 400,
            chars_for_max_duration = 15,
            pulse_count = 2,
            intensity = 1.2,
        },

        custom = {
            max_duration = 350,
            chars_for_max_duration = 40,
            color = hl_visual_bg,

            -- Custom effect function
            -- @param self table The effect object
            -- @param progress number The progress of the animation [0, 1]
            --
            -- Should return a color and a progress value
            -- that represents how much of the animation should be drawn
            effect = function(self, progress)
                return self.settings.color, progress
            end,
        },
    },
    virt_text = {
        priority = 2048,
    },
})
```

For each animation, you can configure the `from_color` and `to_color` options to customize the colors used in the animation. These options should be valid highlight group names, or hexadecimal colors.

Example:
```lua
require('tiny-glimmer').setup({
    animations = {
        fade = {
            from_color = "DiffDelete",
            to_color = "DiffAdd",
        },
        bounce = {
            from_color = "#ff0000",
            to_color = "#00ff00",
        },
    },
})
```

> [!WARNING]
Only `rainbow` animation does not uses `from_color` and `to_color` options.

### Ease Functions

You can use the following easing functions in `fade` and `reverse_fade`:
- linear
- inQuad
- outQuad
- inOutQuad
- outInQuad
- inCubic
- outCubic
- inOutCubic
- outInCubic
- inQuart
- outQuart
- inOutQuart
- outInQuart
- inQuint
- outQuint
- inOutQuint
- outInQuint
- inSine
- outSine
- inOutSine
- outInSine
- inExpo
- outExpo
- inOutExpo
- outInExpo
- inCirc
- outCirc
- inOutCirc
- outInCirc
- inElastic
- outElastic
- inOutElastic
- outInElastic
- inBack
- outBack
- inOutBack
- outInBack
- inBounce
- outBounce
- inOutBounce
- outInBounce

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
- `:TinyGlimmer reverse_fade` - Switch to reverse fade animation
- `:TinyGlimmer bounce` - Switch to bounce animation
- `:TinyGlimmer left_to_right` - Switch to left-to-right animation
- `:TinyGlimmer pulse` - Switch to pulse animation
- `:TinyGlimmer rainbow` - Switch to rainbow animation
- `:TinyGlimmer custom` - Switch to your custom animation

## 🛠️ API

```lua
-- Enable animations
require('tiny-glimmer').enable()

-- Disable animations
require('tiny-glimmer').disable()

-- Toggle animations
require('tiny-glimmer').toggle()

-- When overwrite.search.enabled is true
require('tiny-glimmer').search_next() -- Same as `n`
require('tiny-glimmer').search_prev() -- Same as `N`

-- When overwrite.paste.enabled is true
require('tiny-glimmer').paste() -- Same as `p`
require('tiny-glimmer').Paste() -- Same as `P`
```
Configuration example with overwrites enabled:

```lua
{
    "rachartier/tiny-glimmer.nvim",
    event = "VeryLazy",
    keys = {
        {
            "n",
            function()
                require("tiny-glimmer").search_next()
            end,
            { noremap = true, silent = true },
        },
        {
            "N",
            function()
                require("tiny-glimmer").search_prev()
            end,
            { noremap = true, silent = true },
        },
        {
            "p",
            function()
                require("tiny-glimmer").paste()
            end,
            { noremap = true, silent = true },
        },
        {
            "P",
            function()
                require("tiny-glimmer").Paste()
            end,
            { noremap = true, silent = true },
        },
    },
    opts = {},
}
```
## ❓FAQ

### Why is there two animations playing at the same time?
You should disable your own `TextYankPost` autocmd that calls `vim.highlight.on_yank`


## Thanks

- [EmmanuelOga/easing](https://github.com/EmmanuelOga) for the easing functions

## 📝 License

MIT


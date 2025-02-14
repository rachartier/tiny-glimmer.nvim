# 🌟 tiny-glimmer.nvim

A tiny Neovim plugin that adds subtle animations to various operations.

![Neovim version](https://img.shields.io/badge/Neovim-0.10+-blueviolet.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

> [!WARNING]
>This plugin is still in beta. It is possible that some changes will break the plugin.

## ✨ Features

### Some animations
https://github.com/user-attachments/assets/1bb98834-25d2-4f01-882f-609bec1cbe5c

### Yank & Paste Overwrite
https://github.com/user-attachments/assets/1578d19f-f245-4593-a28f-b7e9593cbc68

### Search Overwrite
https://github.com/user-attachments/assets/6bc98a8f-8b7e-4b57-958a-74ad5372612f

### Undo/Redo support
![tiny_glimmer_demo_undo_redo](https://github.com/user-attachments/assets/6e980884-b425-42d2-a179-6c6126196bd5)



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

    -- Disable this if you wants to debug highlighting issues
    disable_warnings = true,

    default_animation = "fade",
    refresh_interval_ms = 6,

    overwrite = {
        -- Automatically map keys to overwrite operations
        -- If set to false, you will need to call the API functions to trigger the animations
        -- WARN: You should disable this if you have already mapped these keys
        -- 		 or if you want to use the API functions to trigger the animations
        auto_map = true,

        -- For search and paste, you can easily modify the animation to suit your needs
        -- For example you can set a table to default_animation with custom parameters:
        -- default_animation = {
        --     name = "fade",
        --
        --     settings = {
        --         max_duration = 1000,
        --         min_duration = 1000,
        --
        --         from_color = "DiffDelete",
        --         to_color = "Normal",
        --     },
        -- },
        -- settings needs to respect the animation you choose settings
        --
        -- All "mapping" can be set in 2 ways:
        -- 1. A string with the key you want to map
        -- 		  Example:
        -- 			paste_mapping = "p"
        -- 2. A table with the key you want to map and its actions
        -- 		  Example:
        -- 			paste_mapping = {
        -- 				lhs = "p"
        -- 				rhs = "<Plug>(YankyPutAfter)"
        --      }
        search = {
            enabled = false,
            default_animation = "pulse",

            -- Keys to navigate to the next match
            next_mapping = "nzzzv",

            -- Keys to navigate to the previous match
            prev_mapping = "Nzzzv",
        },
        paste = {
            enabled = false,
            default_animation = "reverse_fade",

            -- Keys to paste
            paste_mapping = "p",

            -- Keys to paste above the cursor
            Paste_mapping = "P",
        },
        undo = {
            enabled = false,

            default_animation = {
                name = "fade",

                settings = {
                  from_color = "DiffDelete",

                  max_duration = 500,
                  min_duration = 500,
                },
            },
            undo_mapping = "u",
        },
        redo = {
            enabled = false,

            default_animation = {
                name = "fade",

                settings = {
                    from_color = "DiffAdd",

                    max_duration = 500,
                    min_duration = 500,
                },
            },

            redo_mapping = "<c-r>",
        },
    },


    support = {
        -- Enable support for gbprod/substitute.nvim
        -- You can use it like so:
        -- require("substitute").setup({
        --     on_substitute = require("tiny-glimmer.support.substitute").substitute_cb,
        --     highlight_substituted_text = {
        --         enabled = false,
        --     },
        --})
        substitute = {
            enabled = false,

            -- Can also be a table. Refer to overwrite.search for more information
            default_animation = "fade",
        },
    },


    -- Animations for other operations
    presets = {
        -- Enable animation on cursorline when an event in `on_events` is triggered
        -- Similar to `pulsar.el`
        pulsar = {
            enabled = false,
            on_events = { "CursorMoved", "CmdlineEnter", "WinEnter" },
            default_animation = {
                name = "fade",

                settings = {
                    max_duration = 1000,
                    min_duration = 1000,

                    from_color = "DiffDelete",
                    to_color = "Normal",
                },
            },
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
            min_progress = 0.85,
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

		-- You can add as many animations as you want
        custom = {
            -- You can also add as many custom options as you want
            -- Only `max_duration` and `chars_for_max_duration` is required
            max_duration = 350,
            chars_for_max_duration = 40,

            color = hl_visual_bg,

            -- Custom effect function
            -- @param self table The effect object
            -- @param progress number The progress of the animation [0, 1]
            --
            -- Should return a color and a progress value
            -- that represents how much of the animation should be drawn
            -- self.settings represents the settings of the animation that you defined above
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

--- Change highlight
--- @param animation_name string|string[] The animation name. Can be a string or a table of strings.
---    If a table is passed, each animation will have their highlight changed.
---    If a string is passed, only the provided animation have their highlight changed.
---    You can pass 'all' to change all animations.
--- @param hl table The highlight configuration
-- Examples:
-- require('tiny-glimmer').change_hl('fade', { from_color = '#FF0000', to_color = '#0000FF' })
-- require('tiny-glimmer').change_hl('all', { from_color = '#FF0000', to_color = '#0000FF' })
-- require('tiny-glimmer').change_hl({'fade', 'pulse'}, { from_color = '#FF0000', to_color = '#0000FF' })
require('tiny-glimmer').change_hl(animation_name, hl)

-- When overwrite.search.enabled is true
require('tiny-glimmer').search_next() -- Same as `n`
require('tiny-glimmer').search_prev() -- Same as `N`
require('tiny-glimmer').search_under_cursor() -- Same as `*`

-- When overwrite.paste.enabled is true
require('tiny-glimmer').paste() -- Same as `p`
require('tiny-glimmer').Paste() -- Same as `P`
```

### Keymaps
> [!INFO]
> If you have `overwrite.auto_map` set to `true`, you don't need to set these keymaps.

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
        {
            "*",
            function()
                require("tiny-glimmer").search_under_cursor()
            end,
            { noremap = true, silent = true },
        }
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


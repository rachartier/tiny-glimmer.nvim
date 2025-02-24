# 🌟 tiny-glimmer.nvim

A tiny Neovim plugin that adds subtle animations to various operations.

**Do not forget to enable animations on operations you want to animate ! A lot of operations are disabled by default.**

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
- Smooth animations for various operations:
  - Yank and paste
  - Search navigation
  - Undo/redo operations
  - Custom operations support

Built-in animation styles:
- `fade`: Smooth fade in/out transition
- `reverse_fade`: Reverse fade effect with outBack easing
- `bounce`: Bouncing highlight effect
- `left_to_right`: Linear left-to-right sweep
- `pulse`: Pulsating highlight
- `rainbow`: Rainbow color transition
- `custom`: Define your own animation logic


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

    refresh_interval_ms = 8,

    overwrite = {
        -- Automatically map keys to overwrite operations
        -- If set to false, you will need to call the API functions to trigger the animations
        -- WARN: You should disable this if you have already mapped these keys
        --        or if you want to use the API functions to trigger the animations
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
        -- All "mapping" needs to have a correct lhs.
        -- It will try to automatically use what you already defined before.
        yank = {
              enabled = true,
              default_animation = "fade",
        },
        search = {
            enabled = false,
            default_animation = "pulse",

            -- Keys to navigate to the next match
            next_mapping = "n",

            -- Keys to navigate to the previous match
            prev_mapping = "N",
        },
        paste = {
            enabled = true,
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
     -- Animation configurations
    animations = {
        fade = {
            max_duration = 400,
            min_duration = 300,
            easing = "outQuad",
            chars_for_max_duration = 10,
            from_color = "Visual", -- Highlight group or hex color
            to_color = "Normal", -- Same as above
        },
        reverse_fade = {
            max_duration = 380,
            min_duration = 300,
            easing = "outBack",
            chars_for_max_duration = 10,
            from_color = "Visual",
            to_color = "Normal",
        },
        bounce = {
            max_duration = 500,
            min_duration = 400,
            chars_for_max_duration = 20,
            oscillation_count = 1,
            from_color = "Visual",
            to_color = "Normal",
        },
        left_to_right = {
            max_duration = 350,
            min_duration = 350,
            min_progress = 0.85,
            chars_for_max_duration = 25,
            lingering_time = 50,
            from_color = "Visual",
            to_color = "Normal",
        },
        pulse = {
            max_duration = 600,
            min_duration = 400,
            chars_for_max_duration = 15,
            pulse_count = 2,
            intensity = 1.2,
            from_color = "Visual",
            to_color = "Normal",
        },
        rainbow = {
            max_duration = 600,
            min_duration = 350,
            chars_for_max_duration = 20,
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
        hijack_ft_disabled = {
            "alpha",
            "snacks_dashboard",
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
- `:TinyGlimmer <animation>` - Switch animation style
  - Supported: fade, reverse_fade, bounce, left_to_right, pulse, rainbow, custom

## 🛠️ API
```lua
require('tiny-glimmer').enable()  -- Enable animations
require('tiny-glimmer').disable() -- Disable animations
require('tiny-glimmer').toggle()  -- Toggle animations

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

-- Undo operations (requires undo.enabled = true)
require('tiny-glimmer').undo()   -- Undo changes
require('tiny-glimmer').redo()   -- Redo changes
```

## ❓FAQ

### Why is there two animations playing at the same time?
You should disable your own `TextYankPost` autocmd that calls `vim.highlight.on_yank`

### Transparent background issues?
Set the `transparency_color` option to your desired background color.

### How to use it with `yanky.nvim` ?
You should add `yanky.nvim` in `tiny-glimmer` dependecies.

## Thanks

- [EmmanuelOga/easing](https://github.com/EmmanuelOga) - Easing function implementations
- [tzachar/highlight-undo.nvim](https://github.com/tzachar/highlight-undo.nvim) - Inspiration for hijack function

## 📝 License

MIT


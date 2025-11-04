# 🌟 tiny-glimmer.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.10+-blue.svg)](https://neovim.io/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Stars](https://img.shields.io/github/stars/rachartier/tiny-glimmer.nvim)](https://github.com/rachartier/tiny-glimmer.nvim/stargazers)

A Neovim plugin that adds smooth, customizable animations to text operations like yank, paste, search, undo/redo, and more.

> [!WARNING]
> This plugin is still in beta. Breaking changes may occur in future updates.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
  - [Built-in Animation Styles](#built-in-animation-styles)
  - [Easing Functions](#easing-functions)
  - [Animation Settings](#animation-settings)
- [Examples](#examples)
- [API](#api)
  - [Commands](#commands)
- [Integrations](#integrations)
- [FAQ](#faq)
- [Acknowledgments](#acknowledgments)

## Features

**Smooth animations for various operations:**
- Yank and paste
- Search navigation
- Undo/redo operations
- Custom operations support

**Built-in animation styles:**
- `fade` - Smooth fade in/out transition
- `reverse_fade` - Reverse fade effect with outBack easing
- `bounce` - Bouncing highlight effect
- `left_to_right` - Linear left-to-right sweep
- `pulse` - Pulsating highlight
- `rainbow` - Rainbow color transition
- `custom` - Define your own animation logic

> [!NOTE]
> Many operations are disabled by default. Enable the animations you want to use in your configuration.

## Requirements

- Neovim >= 0.10

## Installation

### Lazy.nvim

```lua
{
    "rachartier/tiny-glimmer.nvim",
    event = "VeryLazy",
    priority = 10, -- Low priority to catch other plugins' keybindings
    config = function()
        require("tiny-glimmer").setup()
    end,
}
```

### Packer.nvim

```lua
use {
    "rachartier/tiny-glimmer.nvim",
    config = function()
        require("tiny-glimmer").setup()
    end
}
```

## Examples

### Some Animations
https://github.com/user-attachments/assets/1bb98834-25d2-4f01-882f-609bec1cbe5c

### Yank & Paste Overwrite
https://github.com/user-attachments/assets/1578d19f-f245-4593-a28f-b7e9593cbc68

### Search Overwrite
https://github.com/user-attachments/assets/6bc98a8f-8b7e-4b57-958a-74ad5372612f

### Undo/Redo Support
https://github.com/user-attachments/assets/5938e28c-2ff3-4e97-8707-67c24e61895c

## Configuration

```lua
require("tiny-glimmer").setup({
    -- Enable/disable the plugin
    enabled = true,

    -- Disable warnings for debugging highlight issues
    disable_warnings = true,

    -- Animation refresh rate in milliseconds
    refresh_interval_ms = 8,

    -- Automatic keybinding overwrites
    overwrite = {
        -- Automatically map keys to overwrite operations
        -- Set to false if you have custom mappings or prefer manual API calls
        auto_map = true,

        -- Yank operation animation
        yank = {
            enabled = true,
            default_animation = "fade",
        },

        -- Search navigation animation
        search = {
            enabled = false,
            default_animation = "pulse",
            next_mapping = "n",      -- Key for next match
            prev_mapping = "N",      -- Key for previous match
        },

        -- Paste operation animation
        paste = {
            enabled = true,
            default_animation = "reverse_fade",
            paste_mapping = "p",     -- Paste after cursor
            Paste_mapping = "P",     -- Paste before cursor
        },

        -- Undo operation animation
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

        -- Redo operation animation
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

    -- Third-party plugin integrations
    support = {
        -- Support for gbprod/substitute.nvim
        -- Usage: require("substitute").setup({
        --     on_substitute = require("tiny-glimmer.support.substitute").substitute_cb,
        --     highlight_substituted_text = { enabled = false },
        -- })
        substitute = {
            enabled = false,
            default_animation = "fade",
        },
    },

    -- Special animation presets
    presets = {
        -- Pulsar-style cursor highlighting on specific events
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

    -- Override background color for animations (for transparent backgrounds)
    transparency_color = nil,

    -- Animation configurations
    animations = {
        fade = {
            max_duration = 400,              -- Maximum animation duration in ms
            min_duration = 300,              -- Minimum animation duration in ms
            easing = "outQuad",              -- Easing function
            chars_for_max_duration = 10,    -- Character count for max duration
            from_color = "Visual",           -- Start color (highlight group or hex)
            to_color = "Normal",             -- End color (highlight group or hex)
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
            oscillation_count = 1,          -- Number of bounces
            from_color = "Visual",
            to_color = "Normal",
        },
        left_to_right = {
            max_duration = 350,
            min_duration = 350,
            min_progress = 0.85,
            chars_for_max_duration = 25,
            lingering_time = 50,            -- Time to linger after completion
            from_color = "Visual",
            to_color = "Normal",
        },
        pulse = {
            max_duration = 600,
            min_duration = 400,
            chars_for_max_duration = 15,
            pulse_count = 2,                -- Number of pulses
            intensity = 1.2,                -- Pulse intensity
            from_color = "Visual",
            to_color = "Normal",
        },
        rainbow = {
            max_duration = 600,
            min_duration = 350,
            chars_for_max_duration = 20,
            -- Note: Rainbow animation does not use from_color/to_color
        },

        -- Custom animation example
        custom = {
            max_duration = 350,
            chars_for_max_duration = 40,
            color = "#ff0000",  -- Custom property

            -- Custom effect function
            -- @param self table - The effect object with settings
            -- @param progress number - Animation progress [0, 1]
            -- @return string color - Hex color or highlight group
            -- @return number progress - How much of the animation to draw
            effect = function(self, progress)
                return self.settings.color, progress
            end,
        },
    },

    -- Filetypes to disable hijacking/overwrites
    hijack_ft_disabled = {
        "alpha",
        "snacks_dashboard",
    },

    -- Virtual text display priority
    virt_text = {
        priority = 2048,  -- Higher values appear above other plugins
    },
})
```

### Built-in Animation Styles

Each animation can be customized with `from_color` and `to_color` options using highlight group names or hex colors:

```lua
require("tiny-glimmer").setup({
    animations = {
        fade = {
            from_color = "DiffDelete",  -- Highlight group
            to_color = "DiffAdd",
        },
        bounce = {
            from_color = "#ff0000",     -- Hex color
            to_color = "#00ff00",
        },
    },
})
```

> [!WARNING]
> The `rainbow` animation does not use `from_color` and `to_color` options.

### Easing Functions

Available easing functions for `fade` and `reverse_fade` animations:

- `linear`
- `inQuad`, `outQuad`, `inOutQuad`, `outInQuad`
- `inCubic`, `outCubic`, `inOutCubic`, `outInCubic`
- `inQuart`, `outQuart`, `inOutQuart`, `outInQuart`
- `inQuint`, `outQuint`, `inOutQuint`, `outInQuint`
- `inSine`, `outSine`, `inOutSine`, `outInSine`
- `inExpo`, `outExpo`, `inOutExpo`, `outInExpo`
- `inCirc`, `outCirc`, `inOutCirc`, `outInCirc`
- `inElastic`, `outElastic`, `inOutElastic`, `outInElastic`
- `inBack`, `outBack`, `inOutBack`, `outInBack`
- `inBounce`, `outBounce`, `inOutBounce`, `outInBounce`

### Animation Settings

Common configuration options across animation types:

| Option | Description | Applicable Animations |
|--------|-------------|----------------------|
| `max_duration` | Maximum duration in milliseconds | All |
| `min_duration` | Minimum duration in milliseconds | All |
| `chars_for_max_duration` | Character count that triggers max duration | All |
| `easing` | Easing function name | fade, reverse_fade |
| `from_color` | Start color (highlight group or hex) | All except rainbow |
| `to_color` | End color (highlight group or hex) | All except rainbow |
| `lingering_time` | Time to stay visible after completion (ms) | left_to_right |
| `oscillation_count` | Number of bounces | bounce |
| `pulse_count` | Number of pulses | pulse |
| `intensity` | Animation intensity multiplier | pulse |

## API

```lua
local glimmer = require("tiny-glimmer")

-- Control plugin state
glimmer.enable()   -- Enable animations
glimmer.disable()  -- Disable animations
glimmer.toggle()   -- Toggle animations on/off

-- Change animation highlights dynamically
-- @param animation_name string|string[] - Animation name(s) or "all"
-- @param hl table - Highlight configuration { from_color = "...", to_color = "..." }
glimmer.change_hl("fade", { from_color = "#FF0000", to_color = "#0000FF" })
glimmer.change_hl("all", { from_color = "#FF0000", to_color = "#0000FF" })
glimmer.change_hl({"fade", "pulse"}, { from_color = "#FF0000", to_color = "#0000FF" })

-- Search operations (when overwrite.search.enabled = true)
glimmer.search_next()          -- Same as "n"
glimmer.search_prev()          -- Same as "N"
glimmer.search_under_cursor()  -- Same as "*"

-- Paste operations (when overwrite.paste.enabled = true)
glimmer.paste()   -- Same as "p"
glimmer.Paste()   -- Same as "P"

-- Undo/redo operations (when undo/redo.enabled = true)
glimmer.undo()    -- Undo changes
glimmer.redo()    -- Redo changes
```

### Commands

```vim
:TinyGlimmer enable         " Enable animations
:TinyGlimmer disable        " Disable animations
:TinyGlimmer fade           " Switch to fade animation
:TinyGlimmer reverse_fade   " Switch to reverse_fade animation
:TinyGlimmer bounce         " Switch to bounce animation
:TinyGlimmer left_to_right  " Switch to left_to_right animation
:TinyGlimmer pulse          " Switch to pulse animation
:TinyGlimmer rainbow        " Switch to rainbow animation
:TinyGlimmer custom         " Switch to custom animation
```

Keybinding examples:

```lua
vim.keymap.set("n", "<leader>ge", "<cmd>TinyGlimmer enable<cr>", { desc = "Enable animations" })
vim.keymap.set("n", "<leader>gd", "<cmd>TinyGlimmer disable<cr>", { desc = "Disable animations" })
vim.keymap.set("n", "<leader>gt", "<cmd>TinyGlimmer fade<cr>", { desc = "Switch to fade" })
```

## Integrations

### gbprod/substitute.nvim

Add animation support to the substitute plugin:

```lua
{
    "gbprod/substitute.nvim",
    dependencies = { "rachartier/tiny-glimmer.nvim" },
    config = function()
        require("substitute").setup({
            on_substitute = require("tiny-glimmer.support.substitute").substitute_cb,
            highlight_substituted_text = {
                enabled = false,  -- Disable built-in highlight
            },
        })
    end,
}
```

Then enable it in tiny-glimmer config:

```lua
require("tiny-glimmer").setup({
    support = {
        substitute = {
            enabled = true,
            default_animation = "fade",
        },
    },
})
```

### yanky.nvim

Add `yanky.nvim` to tiny-glimmer dependencies to ensure proper loading order:

```lua
{
    "rachartier/tiny-glimmer.nvim",
    dependencies = { "gbprod/yanky.nvim" },
    event = "VeryLazy",
    priority = 10,
    config = function()
        require("tiny-glimmer").setup()
    end,
}
```

## FAQ

### Why are two animations playing at the same time?

Disable your `TextYankPost` autocmd that calls `vim.highlight.on_yank`:

```lua
-- Remove or comment out this:
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank()
    end,
})
```

### Transparent background issues?

Set the `transparency_color` option to match your background:

```lua
require("tiny-glimmer").setup({
    transparency_color = "#000000",  -- Your background color
})
```

### How to use custom animations?

Define a custom animation in the `animations` table:

```lua
require("tiny-glimmer").setup({
    animations = {
        my_custom = {
            max_duration = 400,
            chars_for_max_duration = 10,
            custom_property = "value",
            
            effect = function(self, progress)
                -- Your animation logic here
                return "#ff0000", progress
            end,
        },
    },
    overwrite = {
        yank = {
            enabled = true,
            default_animation = "my_custom",
        },
    },
})
```

### Animations not working?

Check these common issues:
- Ensure the operation is enabled in `overwrite` config
- Verify `auto_map = true` or set up manual keybindings
- Check if the filetype is in `hijack_ft_disabled`
- Confirm animations are enabled: `:TinyGlimmer enable`

### How to disable for specific filetypes?

Add them to the `hijack_ft_disabled` list:

```lua
require("tiny-glimmer").setup({
    hijack_ft_disabled = {
        "alpha",
        "dashboard",
        "neo-tree",
    },
})
```

## Acknowledgments

- [EmmanuelOga/easing](https://github.com/EmmanuelOga/easing) - Easing function implementations
- [tzachar/highlight-undo.nvim](https://github.com/tzachar/highlight-undo.nvim) - Inspiration for hijack functionality

## License

MIT

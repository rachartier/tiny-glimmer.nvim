# 🌟 tiny-glimmer.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.10+-blue.svg)](https://neovim.io/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Stars](https://img.shields.io/github/stars/rachartier/tiny-glimmer.nvim)](https://github.com/rachartier/tiny-glimmer.nvim/stargazers)

A Neovim plugin that adds smooth, customizable animations to text operations like yank, paste, search, undo/redo, and more.

> [!WARNING]
> This plugin is still in beta. Breaking changes may occur in future updates.



https://github.com/user-attachments/assets/745cb1e3-9904-4718-9804-ac0a4fee8748



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
- [Library API](#library-api)
  - [Quick Start](#quick-start)
  - [Core Functions](#core-functions)
  - [Helper Functions](#helper-functions)
  - [Range Utilities](#range-utilities)
  - [Advanced Usage](#advanced-usage)
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

## Library API

The `tiny-glimmer.lib` module provides a low-level API for creating custom animations programmatically. This is useful for integrating animations into your own plugins or creating custom keybindings.

### Quick Start

```lua
local glimmer = require("tiny-glimmer.lib")

-- Animate current line with fade effect
vim.keymap.set("n", "<leader>al", function()
  glimmer.cursor_line("fade")
end)

-- Animate visual selection
vim.keymap.set("v", "<leader>av", function()
  glimmer.visual_selection("pulse")
end)

-- Create custom animation on specific range
vim.keymap.set("n", "<leader>ac", function()
  glimmer.create_animation({
    range = glimmer.get_line_range(0),
    duration = 500,
    from_color = "#ff0000",
    to_color = "#00ff00",
    effect = "fade",
  })
end)
```

### Core Functions

#### `create_animation(opts)`

Create a simple text animation with full control over parameters.

```lua
glimmer.create_animation({
  range = {
    start_line = 0,      -- 0-indexed start line
    start_col = 0,       -- 0-indexed start column
    end_line = 0,        -- 0-indexed end line
    end_col = 10,        -- 0-indexed end column
  },
  duration = 300,        -- Animation duration in ms
  from_color = "#ff0000",  -- Start color (hex or highlight group)
  to_color = "#00ff00",    -- End color (hex or highlight group)
  effect = "fade",       -- Effect type (fade, pulse, bounce, etc.)
  easing = "outQuad",    -- Easing function (optional)
  on_complete = function()  -- Callback when done (optional)
    print("Animation complete!")
  end,
  loop = false,          -- Whether to loop (optional)
  loop_count = 1,        -- Number of loops, 0 = infinite (optional)
})
```

**Parameters:**
- `range` (AnimationRange, required) - Text range to animate
- `duration` (number, required) - Animation duration in milliseconds
- `from_color` (string, required) - Start color (hex color or highlight group name)
- `to_color` (string, required) - End color (hex color or highlight group name)
- `effect` (string, optional) - Effect type, defaults to "fade"
- `easing` (string, optional) - Easing function, defaults to "linear"
- `on_complete` (function, optional) - Callback when animation completes
- `loop` (boolean, optional) - Whether to loop the animation
- `loop_count` (number, optional) - Number of times to loop (0 = infinite)

#### `create_line_animation(opts)`

Create a line-based animation that highlights entire lines (ignores column positions).

```lua
glimmer.create_line_animation({
  range = glimmer.get_line_range(1),
  duration = 400,
  from_color = "DiffAdd",
  to_color = "Normal",
  effect = "pulse",
})
```

Parameters are the same as `create_animation()`, but `start_col` and `end_col` are ignored.

#### `create_text_animation(opts)`

Alias for `create_animation()` that highlights specific character ranges.

#### `create_named_animation(name, opts)`

Create a named animation that can be stopped later using its name.

```lua
-- Start an infinite rainbow effect
glimmer.create_named_animation("rainbow_loop", {
  range = glimmer.get_line_range(0),
  duration = 1000,
  from_color = "#ff0000",
  to_color = "#00ff00",
  effect = "rainbow",
  loop = true,
  loop_count = 0,  -- Infinite
})

-- Stop it later
vim.keymap.set("n", "<leader>x", function()
  glimmer.stop_animation("rainbow_loop")
end)
```

**Parameters:**
- `name` (string, required) - Unique identifier for this animation
- `opts` (table, required) - Same options as `create_animation()`

#### `stop_animation(name)`

Stop a named animation.

```lua
glimmer.stop_animation("my_animation_name")
```

#### `create_effect(opts)`

Create a custom effect with your own update function.

```lua
local effect = glimmer.create_effect({
  settings = {
    max_duration = 500,
    min_duration = 300,
    chars_for_max_duration = 10,
    custom_color = "#ff00ff",
  },
  update_fn = function(self, progress)
    -- Return color and progress for current frame
    -- progress is between 0 and 1
    local alpha = math.floor(progress * 255)
    local color = string.format("#%02x00ff", alpha)
    return color, progress
  end,
  builder = function(self)
    -- Optional: Build initial data
    return { initial_state = true }
  end,
})
```

### Helper Functions

Convenience functions for common animation patterns.

#### `cursor_line(effect, opts)`

Animate the current cursor line.

```lua
-- Simple usage
glimmer.cursor_line("pulse")

-- With custom settings
glimmer.cursor_line("fade", {
  max_duration = 600,
  from_color = "#ff0000",
  loop = true,
  loop_count = 3,
})

-- With effect configuration
glimmer.cursor_line({
  name = "pulse",
  settings = {
    max_duration = 800,
    pulse_count = 3,
  }
})
```

#### `visual_selection(effect, opts)`

Animate the current visual selection.

```lua
vim.keymap.set("v", "<leader>v", function()
  glimmer.visual_selection("bounce", {
    max_duration = 500,
  })
end)
```

#### `animate_range(effect, range, opts)`

Animate a specific range with an effect.

```lua
local range = {
  start_line = 5,
  start_col = 0,
  end_line = 10,
  end_col = 20,
}
glimmer.animate_range("fade", range, {
  from_color = "DiffDelete",
  to_color = "Normal",
})
```

#### `named_animate_range(name, effect, range, opts)`

Create a named animation for a specific range.

```lua
glimmer.named_animate_range("highlight_1", "rainbow", glimmer.get_line_range(5), {
  loop = true,
  loop_count = 0,
})

-- Stop it later
glimmer.stop_animation("highlight_1")
```

### Range Utilities

Functions to get text ranges from various sources.

#### `get_cursor_range()`

Get the range of the current cursor position (single character).

```lua
local range = glimmer.get_cursor_range()
-- Returns: { start_line = 0, start_col = 5, end_line = 0, end_col = 6 }
```

#### `get_visual_range()`

Get the range of the current visual selection.

```lua
-- In visual mode
local range = glimmer.get_visual_range()
if range then
  glimmer.animate_range("fade", range)
end
```

Returns `nil` if no visual selection exists.

#### `get_line_range(line)`

Get the range for a specific line.

```lua
-- Get current line (0 or nil)
local current_line = glimmer.get_line_range(0)

-- Get line 5 (1-indexed)
local line_5 = glimmer.get_line_range(5)
```

**Parameters:**
- `line` (number) - 1-indexed line number, or 0 for current line

#### `get_yank_range()`

Get the range from the last yank operation.

```lua
local range = glimmer.get_yank_range()
if range then
  glimmer.animate_range("pulse", range)
end
```

Returns `nil` if no yank operation has occurred.

### Advanced Usage

#### Looping Animations

```lua
-- Loop 3 times
glimmer.create_animation({
  range = glimmer.get_line_range(0),
  duration = 200,
  from_color = "#ff0000",
  to_color = "#00ff00",
  loop = true,
  loop_count = 3,
  on_complete = function()
    print("Looped 3 times!")
  end,
})

-- Infinite loop (must be named to stop)
glimmer.create_named_animation("infinite", {
  range = glimmer.get_line_range(0),
  duration = 500,
  from_color = "Visual",
  to_color = "Normal",
  effect = "pulse",
  loop = true,
  loop_count = 0,  -- 0 = infinite
})

-- Stop it when done
vim.defer_fn(function()
  glimmer.stop_animation("infinite")
end, 5000)
```

#### Multiple Animations

```lua
-- Animate multiple lines at once
vim.keymap.set("n", "<leader>am", function()
  local start_line = vim.api.nvim_win_get_cursor(0)[1]
  for i = 0, 4 do
    glimmer.create_line_animation({
      range = glimmer.get_line_range(start_line + i),
      duration = 300 + (i * 50),  -- Stagger durations
      from_color = "#ff0000",
      to_color = "#00ff00",
      effect = "fade",
    })
  end
end)
```

#### Custom Autocmd Integration

```lua
-- Animate on buffer write
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    glimmer.cursor_line("pulse", {
      max_duration = 300,
      from_color = "DiffAdd",
    })
  end,
})

-- Animate search results
vim.keymap.set("n", "n", function()
  vim.cmd("normal! n")
  local pos = vim.api.nvim_win_get_cursor(0)
  glimmer.create_animation({
    range = glimmer.get_cursor_range(),
    duration = 400,
    from_color = "IncSearch",
    to_color = "Normal",
    effect = "pulse",
  })
end)
```

For more examples, see the [examples/](examples/) directory in the repository.

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

### Search keys not working with Lazy Vim?

When using Lazy Vim with search animations enabled, you may need to add the `keys` property to your plugin specification to ensure proper key mapping:

```lua
{
    "rachartier/tiny-glimmer.nvim",
    event = "VeryLazy",
    priority = 10,
    keys = {
        "n",
        "N",
    },
    config = function()
        require("tiny-glimmer").setup({
            overwrite = {
                search = {
                    enabled = true,
                },
            },
        })
    end,
}
```

This tells Lazy Vim to load the plugin when the `n` or `N` keys are pressed, ensuring the plugin's key mappings take precedence.

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

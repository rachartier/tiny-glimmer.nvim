return {
  enabled = true,
  disable_warnings = true,
  autoreload = false,

  overwrite = {
    auto_map = true,
    search = {
      enabled = false,
      default_animation = {
        name = "pulse",

        settings = {
          to_color = vim.opt.hlsearch and "CurSearch" or "Search",
        },
      },

      next_mapping = "n",
      prev_mapping = "N",
      next_under_cursor_mapping = "*",
      prev_under_cursor_mapping = "#",
    },
    paste = {
      enabled = true,
      default_animation = "reverse_fade",

      paste_mapping = "p",
      Paste_mapping = "P",
    },
    yank = {
      enabled = true,
      default_animation = "fade",
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
    substitute = {
      enabled = false,
      default_animation = "fade",
    },
  },

  presets = {
    pulsar = {
      enabled = false,

      on_event = { "WinEnter", "CmdlineLeave", "BufEnter" },
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

  refresh_interval_ms = 8,
  transparency_color = nil,
  text_change_batch_timeout_ms = 50,

  animations = {
    fade = {
      max_duration = 400,
      min_duration = 300,
      easing = "outQuad",
      chars_for_max_duration = 10,
      from_color = "Visual",
      to_color = "Normal",
      font_style = {},
    },
    reverse_fade = {
      max_duration = 380,
      min_duration = 300,
      easing = "outBack",
      chars_for_max_duration = 10,
      from_color = "Visual",
      to_color = "Normal",
      font_style = {},
    },
    bounce = {
      max_duration = 500,
      min_duration = 400,
      chars_for_max_duration = 20,
      oscillation_count = 1,
      from_color = "Visual",
      to_color = "Normal",
      font_style = {},
    },
    left_to_right = {
      max_duration = 350,
      min_duration = 350,
      easing = "easeInExpo",
      lingering_time = 50,
      chars_for_max_duration = 25,
      from_color = "Visual",
      to_color = "Normal",
      font_style = {},
    },
    pulse = {
      max_duration = 600,
      min_duration = 400,
      chars_for_max_duration = 15,
      pulse_count = 2,
      intensity = 1.2,
      from_color = "Visual",
      to_color = "Normal",
      font_style = {},
    },
    rainbow = {
      max_duration = 600,
      min_duration = 350,
      chars_for_max_duration = 20,
      font_style = {},
    },
    custom = {
      max_duration = 350,
      min_duration = 200,
      chars_for_max_duration = 40,
      color = "Visual",
      font_style = {},

      effect = function(self, progress)
        return self.settings.color, progress
      end,
    },
  },
  virt_text = {
    priority = 2048,
  },
  hijack_ft_disabled = {
    "alpha",
    "snacks_dashboard",
    "snacks_picker_input",
  },
}

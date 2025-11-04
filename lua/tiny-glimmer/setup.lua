local M = {}

local function setup_hijacks(config, custom_remap_fn)
  -- stylua: ignore start
  if config.overwrite.auto_map then
    local search_config = config.overwrite.search
    if search_config.enabled then
      custom_remap_fn(search_config.next_mapping, "n", function() require("tiny-glimmer").search_next() end)
      custom_remap_fn(search_config.prev_mapping, "n", function() require("tiny-glimmer").search_prev() end)
      custom_remap_fn(search_config.next_under_cursor_mapping, "n", function() require("tiny-glimmer").search_under_cursor() end)
      custom_remap_fn(search_config.prev_under_cursor_mapping, "n", function() require("tiny-glimmer").search_under_cursor() end)

      if vim.opt.hlsearch then
        local utils = require("tiny-glimmer.utils")
        local normal_hl = utils.get_highlight("Normal")
        vim.api.nvim_set_hl(0, "CurSearch", {
          bg = "None",
          fg = normal_hl.fg
        })
      end
    end

    local paste_config = config.overwrite.paste
    if paste_config.enabled then
      custom_remap_fn(paste_config.paste_mapping, "n", function() require("tiny-glimmer").paste() end)
      custom_remap_fn(paste_config.Paste_mapping, "n", function() require("tiny-glimmer").Paste() end)
    end

    local undo_config = config.overwrite.undo
    local redo_config = config.overwrite.redo
    if undo_config.enabled then
      custom_remap_fn(undo_config.undo_mapping, "n", function() require("tiny-glimmer").undo() end)
    end
    if redo_config.enabled then
      custom_remap_fn(redo_config.redo_mapping, "n", function() require("tiny-glimmer").redo() end)
    end
  end
  -- stylua: ignore end
end

function M.initialize(user_options)
  local defaults = require("tiny-glimmer.config.defaults")
  local highlights = require("tiny-glimmer.config.highlights")
  local AnimationFactory = require("tiny-glimmer.animation.factory")
  local Effect = require("tiny-glimmer.animation.effect")
  local namespace = require("tiny-glimmer.namespace").tiny_glimmer_animation_group

  -- Merge configuration
  local config = vim.tbl_deep_extend("force", defaults, user_options or {})

  -- Sanitize highlights
  highlights.sanitize_highlights(config)

  -- Setup effects pool
  local effects_pool = require("tiny-glimmer.premade_effects")
  for name, effect_settings in pairs(config.animations) do
    if not effects_pool[name] then
      effects_pool[name] = Effect.new(effect_settings, effect_settings.effect)
    else
      effects_pool[name]:update_settings(effect_settings)
    end
  end

  -- Initialize support modules
  for support_name, support_settings in pairs(config.support) do
    if support_settings.enabled then
      local ok, support = pcall(require, "tiny-glimmer.support." .. support_name)
      if ok and support.setup then
        support.setup(support_settings)
      end
    end
  end

  -- Initialize overwrite modules
  for overwrite_name, overwrite_settings in pairs(config.overwrite) do
    if type(overwrite_settings) == "table" then
      if overwrite_settings.enabled then
        local ok, overwrite_module = pcall(require, "tiny-glimmer.overwrite." .. overwrite_name)
        if ok and overwrite_module.setup then
          overwrite_module.setup(overwrite_settings)
        end
      end
    end
  end

  -- Initialize presets
  if config.presets.pulsar.enabled then
    require("tiny-glimmer.presets.pulsar").setup(config.presets.pulsar)
  end

  -- Initialize animation factory
  AnimationFactory.initialize(config, effects_pool, config.refresh_interval_ms)

  -- Setup hijacks
  local glimmer = require("tiny-glimmer")
  if vim.tbl_contains(config.hijack_ft_disabled, vim.bo.filetype) then
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
      group = namespace,
      callback = function()
        if glimmer.hijack_done then
          return
        end
        if not vim.tbl_contains(config.hijack_ft_disabled, vim.bo.filetype) then
          setup_hijacks(config, glimmer.custom_remap)
          glimmer.hijack_done = true
        end
      end,
    })
  else
    setup_hijacks(config, glimmer.custom_remap)
  end

  -- Create autocmds for buffer cleanup
  vim.api.nvim_create_autocmd({ "BufEnter", "BufLeave" }, {
    group = namespace,
    callback = function()
      local ns = require("tiny-glimmer.namespace").tiny_glimmer_animation_ns
      vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
    end,
  })

  -- Create user command
  vim.api.nvim_create_user_command("TinyGlimmer", function(args)
    local command = args.args
    if command == "enable" then
      config.enabled = true
    elseif command == "disable" then
      config.enabled = false
    else
      vim.notify(
        "Usage: TinyGlimmer [enable|disable|fade|reverse_fade|bounce|left_to_right|pulse|rainbow|custom]",
        vim.log.levels.INFO
      )
    end
  end, {
    nargs = 1,
    complete = function()
      return {
        "enable",
        "disable",
        "fade",
        "reverse_fade",
        "bounce",
        "left_to_right",
        "pulse",
        "rainbow",
        "custom",
      }
    end,
  })

  return config
end

return M

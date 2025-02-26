local M = {}

local overwrite = require("tiny-glimmer.overwrite")
local utils = require("tiny-glimmer.utils")

local AnimationFactory = require("tiny-glimmer.animation.factory")
local Effect = require("tiny-glimmer.animation.effect")

local hl_visual_bg = utils.int_to_hex(utils.get_highlight("Visual").bg)
local hl_normal_bg = utils.int_to_hex(utils.get_highlight("Normal").bg)

local hijack_done = false

local animation_group = require("tiny-glimmer.namespace").tiny_glimmer_animation_group

M.config = {
	enabled = true,
	disable_warnings = true,

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

	animations = {
		fade = {
			max_duration = 400,
			min_duration = 300,
			easing = "outQuad",
			chars_for_max_duration = 10,
			from_color = hl_visual_bg,
			to_color = hl_normal_bg,
		},
		reverse_fade = {
			max_duration = 380,
			min_duration = 300,
			easing = "outBack",
			chars_for_max_duration = 10,
			from_color = hl_visual_bg,
			to_color = hl_normal_bg,
		},
		bounce = {
			max_duration = 500,
			min_duration = 400,
			chars_for_max_duration = 20,
			oscillation_count = 1,
			from_color = hl_visual_bg,
			to_color = hl_normal_bg,
		},
		left_to_right = {
			max_duration = 350,
			min_duration = 350,
			min_progress = 0.85,
			chars_for_max_duration = 25,
			lingering_time = 50,
			from_color = hl_visual_bg,
			to_color = hl_normal_bg,
		},
		pulse = {
			max_duration = 600,
			min_duration = 400,
			chars_for_max_duration = 15,
			pulse_count = 2,
			intensity = 1.2,
			from_color = hl_visual_bg,
			to_color = hl_normal_bg,
		},
		rainbow = {
			max_duration = 600,
			min_duration = 350,
			chars_for_max_duration = 20,
		},
		custom = {
			max_duration = 350,
			min_duration = 200,
			chars_for_max_duration = 40,
			color = hl_visual_bg,

			--- Custom effect function
			--- @param self table The effect object
			--- @param progress number The progress of the animation [0, 1]
			---
			--- Should return a color and a progress value
			--- that represents how much of the animation should be drawn
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
	},
}

-- Helper Functions
local function process_highlight_color(color, highlight_name, is_from_color, options)
	if not color or color:sub(1, 1) == "#" then
		return color
	end

	local converted_color = utils.int_to_hex(utils.get_highlight(color).bg)

	if converted_color:lower() == "none" then
		if options.transparency_color then
			return options.transparency_color
		end

		local is_transparent = utils.get_highlight("Normal").bg == nil or utils.get_highlight("Normal").bg == "None"

		if not is_transparent then
			local default_highlight = is_from_color and "Visual" or "Normal"
			if not options.disable_warnings then
				local msg = string.format(
					"TinyGlimmer: %s_color is set to None for %s animation\nDefaulting to %s highlight",
					is_from_color and "from" or "to",
					highlight_name,
					default_highlight
				)
				vim.notify(msg, vim.log.levels.WARN)
			end
			return is_from_color and hl_visual_bg or hl_normal_bg
		end
		return "#000000"
	end

	return converted_color
end

local function process_animation_colors(animation, name, options)
	if type(animation) == "table" then
		animation.settings.from_color = process_highlight_color(animation.settings.from_color, name, true, options)
		animation.settings.to_color = process_highlight_color(animation.settings.to_color, name, false, options)
	end
end

local function validate_transparency(options)
	local normal_bg = utils.get_highlight("Normal").bg
	local is_transparent = normal_bg == nil or normal_bg == "None"

	if is_transparent and not options.transparency_color and not options.disable_warnings then
		vim.notify(
			"TinyGlimmer: Normal highlight group has a transparent background.\n"
				.. "Please set the transparency_color option to a valid color",
			vim.log.levels.WARN
		)
	end
end

-- Main Functions
local function sanitize_highlights(options)
	validate_transparency(options)

	-- Process animation colors
	for name, highlight in pairs(options.animations) do
		highlight.from_color = process_highlight_color(highlight.from_color, name, true, options)
		highlight.to_color = process_highlight_color(highlight.to_color, name, false, options)
	end

	-- Process preset colors
	for name, preset in pairs(options.presets) do
		if preset.default_animation then
			if type(preset.default_animation) == "string" then
				preset.default_animation = options.animations[preset.default_animation]
			end
			process_animation_colors(preset.default_animation, name, options)
		end
	end

	-- Process overwrite and support colors
	for _, category in ipairs({ options.overwrite, options.support }) do
		for name, preset in pairs(category) do
			if type(preset) == "table" and preset.default_animation then
				process_animation_colors(preset.default_animation, name, options)
			end
		end
	end
end

function M.custom_remap(map, mode, callback)
	local lhs = map
	local rhs = nil

	if type(map) == "table" then
		lhs = map.lhs
		rhs = map.rhs
	else
		if map:lower() == "<c-r>" then
			lhs = "<c-r>"
		else
			lhs = map:sub(1, 1)
		end
	end

	local original_mapping = vim.fn.maparg(lhs, mode, false, true)
	require("tiny-glimmer.hijack").hijack(mode, lhs, rhs, original_mapping, callback)
end

local function setup_hijacks()
    -- stylua: ignore start
    if M.config.overwrite.auto_map then
        local search_config = M.config.overwrite.search
        if search_config.enabled then
            M.custom_remap(search_config.next_mapping, "n", function() require("tiny-glimmer").search_next() end)
            M.custom_remap(search_config.prev_mapping, "n", function() require("tiny-glimmer").search_prev() end)
            M.custom_remap(search_config.next_under_cursor_mapping, "n", function() require("tiny-glimmer").search_under_cursor() end)
            M.custom_remap(search_config.prev_under_cursor_mapping, "n", function() require("tiny-glimmer").search_under_cursor() end)

            if vim.opt.hlsearch then
                local normal_hl = utils.get_highlight("Normal")

                vim.api.nvim_set_hl(0, "CurSearch", {
                    bg = "None",
                    fg = normal_hl.fg
                })
            end
        end

        local paste_config = M.config.overwrite.paste
        if paste_config.enabled then
            M.custom_remap(paste_config.paste_mapping, "n", function() require("tiny-glimmer").paste() end)
            M.custom_remap(paste_config.Paste_mapping, "n", function() require("tiny-glimmer").Paste() end)
        end

        local undo_config = M.config.overwrite.undo
        local redo_config = M.config.overwrite.redo
        if undo_config.enabled then
            M.custom_remap(undo_config.undo_mapping, "n", function() require("tiny-glimmer").undo() end)
        end

        if redo_config.enabled then
            M.custom_remap(redo_config.redo_mapping, "n", function() require("tiny-glimmer").redo() end)
        end
    end
	-- stylua: ignore end
end

function M.setup(options)
	M.config = vim.tbl_deep_extend("force", M.config, options or {})
	sanitize_highlights(M.config)

	local effects_pool = require("tiny-glimmer.premade_effects")

	for name, effect_settings in pairs(M.config.animations) do
		if not effects_pool[name] then
			effects_pool[name] = Effect.new(effect_settings, effect_settings.effect)
		else
			effects_pool[name]:update_settings(effect_settings)
		end
	end

	for support_name, support_settings in pairs(M.config.support) do
		if support_settings.enabled then
			local ok, support = pcall(require, "tiny-glimmer.support." .. support_name)
			if ok and support.setup then
				support.setup(support_settings)
			end
		end
	end

	for overwrite_name, overwrite_settings in pairs(M.config.overwrite) do
		if type(overwrite_settings) == "table" then
			if overwrite_settings.enabled then
				local ok, overwrite_module = pcall(require, "tiny-glimmer.overwrite." .. overwrite_name)
				if ok and overwrite_module.setup then
					overwrite_module.setup(overwrite_settings)
				end
			end
		end
	end

	if M.config.presets.pulsar.enabled then
		require("tiny-glimmer.presets.pulsar").setup(M.config.presets.pulsar)
	end

	AnimationFactory.initialize(M.config, effects_pool, M.config.refresh_interval_ms)

	vim.schedule(function()
		setup_hijacks()
	end)

	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function(event)
			if hijack_done then
				return
			end

			if vim.tbl_contains(M.config.hijack_ft_disabled, vim.bo.filetype) then
				return
			end

			setup_hijacks()
			hijack_done = true
		end,
	})
	vim.api.nvim_create_autocmd({ "BufEnter", "BufLeave" }, {
		group = animation_group,
		callback = function()
			local namespace = require("tiny-glimmer.namespace").tiny_glimmer_animation_ns
			vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
		end,
	})
end

vim.api.nvim_create_user_command("TinyGlimmer", function(args)
	local command = args.args
	if command == "enable" then
		M.config.enabled = true
	elseif command == "disable" then
		M.config.enabled = false
	elseif effects[command] or command == "custom" then
		M.config.default_animation = command
	else
		vim.notify(
			"Usage: TinyGlimmer [enable|disable|fade|reverse_fade|bounce|left_to_right|pulse|rainbow|custom]",
			vim.log.levels.INFO
		)
	end
end, {
	nargs = 1,
	complete = function()
		return { "enable", "disable", "fade", "reverse_fade", "bounce", "left_to_right", "pulse", "rainbow", "custom" }
	end,
})

--- Disable the animation
M.disable = function()
	M.config.enabled = false
end

--- Enable the animation
M.enable = function()
	M.config.enabled = true
end

--- Toggle the plugin on or off
M.toggle = function()
	M.config.enabled = not M.config.enabled
end

M.change_hl = function(animation_name, hl)
	local function change_animation_hl(animation, hl)
		if hl.from_color then
			animation.from_color = hl.from_color
		end

		if hl.to_color then
			animation.to_color = hl.to_color
		end
	end

	if animation_name == "all" then
		for _, animation in pairs(M.config.animations) do
			change_animation_hl(animation, hl)
		end
		sanitize_highlights(M.config)
		return
	end

	if type(animation_name) == "table" then
		for _, name in ipairs(animation_name) do
			if not M.config.animations[name] then
				vim.notify("TinyGlimmer: Animation " .. name .. " not found. Skipping", vim.log.levels.WARN)
			end

			M.change_hl(name, hl)
		end
		sanitize_highlights(M.config)
		return
	end

	if not M.config.animations[animation_name] then
		vim.notify("TinyGlimmer: Animation " .. animation_name .. " not found", vim.log.levels.ERROR)
		return
	end

	local animation = M.config.animations[animation_name]

	change_animation_hl(animation, hl)

	M.config.animations[animation] = animation

	sanitize_highlights(M.config)
end

--- Get the background highlight color for the given highlight name
--- @param hl_name string
--- @return string Hex color
M.get_background_hl = function(hl_name)
	return utils.int_to_hex(utils.get_highlight(hl_name).bg)
end

M.search_next = function()
	if not M.config.overwrite.search.enabled then
		vim.notify(
			'TinyGlimmer: Search is not enabled in your configuration.\nYou should not use require("tiny-glimmer").search_next().',
			vim.log.levels.WARN
		)
	end

	overwrite.search.search_next(M.config.overwrite.search)
end

M.search_prev = function()
	if not M.config.overwrite.search.enabled then
		vim.notify(
			'TinyGlimmer: Search is not enabled in your configuration.\nYou should not use require("tiny-glimmer").search_prev().',
			vim.log.levels.WARN
		)
	end
	overwrite.search.search_prev(M.config.overwrite.search)
end

M.paste = function()
	if not M.config.overwrite.paste.enabled then
		vim.notify(
			'TinyGlimmer: Paste is not enabled in your configuration.\nYou should not use require("tiny-glimmer").paste().',
			vim.log.levels.WARN
		)
	end
	overwrite.paste.paste(M.config.overwrite.paste)
end

M.Paste = function()
	if not M.config.overwrite.paste.enabled then
		vim.notify(
			'TinyGlimmer: Paste is not enabled in your configuration.\nYou should not use require("tiny-glimmer").Paste.',
			vim.log.levels.WARN
		)
	end

	overwrite.paste.Paste(M.config.overwrite.paste)
end

M.undo = function()
	if not M.config.overwrite.undo.enabled then
		vim.notify(
			'TinyGlimmer: Undo is not enabled in your configuration.\nYou should not use require("tiny-glimmer").undo().',
			vim.log.levels.WARN
		)
	end
	overwrite.undo.undo(M.config.overwrite.undo)
end

M.redo = function()
	if not M.config.overwrite.undo.enabled then
		vim.notify(
			'TinyGlimmer: Undo is not enabled in your configuration.\nYou should not use require("tiny-glimmer").redo().',
			vim.log.levels.WARN
		)
	end
	overwrite.undo.redo(M.config.overwrite.redo)
end

M.search_under_cursor = function()
	if not M.config.overwrite.search.enabled then
		vim.notify(
			'TinyGlimmer: Search is not enabled in your configuration.\nYou should not use require("tiny-glimmer").search_under_cursor().',
			vim.log.levels.WARN
		)
	end
	overwrite.search.search_under_cursor(M.config.overwrite.search)
end

return M

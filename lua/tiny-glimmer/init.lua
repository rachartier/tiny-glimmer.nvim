local M = {}

local overwrite = require("tiny-glimmer.overwrite")
local utils = require("tiny-glimmer.utils")

local AnimationFactory = require("tiny-glimmer.animation_factory")
local Effect = require("tiny-glimmer.effect")

local hl_visual_bg = utils.int_to_hex(utils.get_highlight("Visual").bg)
local hl_normal_bg = utils.int_to_hex(utils.get_highlight("Normal").bg)

M.config = {
	enabled = true,

	overwrite = {
		auto_map = true,
		search = {
			enabled = false,
			default_animation = "pulse",

			next_mapping = "nzzzv",
			prev_mapping = "Nzzzv",
		},
		paste = {
			enabled = true,
			default_animation = "reverse_fade",

			paste_mapping = "p=`]",
			Paste_mapping = "P=`]",
		},
	},

	default_animation = "fade",
	refresh_interval_ms = 6,
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
}

local function sanitize_highlights(options)
	local normal_bg = utils.get_highlight("Normal").bg
	local is_transparent = normal_bg == nil or normal_bg == "None"

	if is_transparent and not options.transparency_color then
		vim.notify(
			"TinyGlimmer: Normal highlight group has a transparent background.\n"
				.. "Please set the transparency_color option to a valid color",
			vim.log.levels.WARN
		)
	end

	local function process_color(color, highlight_name, is_from_color)
		if not color or color:sub(1, 1) == "#" then
			return color
		end

		local converted_color = utils.int_to_hex(utils.get_highlight(color).bg)

		if converted_color:lower() == "none" then
			if options.transparency_color then
				return options.transparency_color
			end

			if not is_transparent then
				local default_highlight = is_from_color and "Visual" or "Normal"
				vim.notify(
					string.format(
						"TinyGlimmer: %s_color is set to None for %s animation\n" .. "Defaulting to %s highlight",
						is_from_color and "from" or "to",
						highlight_name,
						default_highlight
					),
					vim.log.levels.WARN
				)
				return is_from_color and hl_visual_bg or hl_normal_bg
			else
				return "#000000"
			end
		end

		return converted_color
	end

	for name, highlight in pairs(options.animations) do
		highlight.from_color = process_color(highlight.from_color, name, true)
		highlight.to_color = process_color(highlight.to_color, name, false)
	end
end

function M.setup(options)
	M.config = vim.tbl_deep_extend("force", M.config, options or {})
	sanitize_highlights(M.config)

	local animation_group = vim.api.nvim_create_augroup("TinyGlimmer", { clear = true })
	local effects_pool = require("tiny-glimmer.premade_effects")

	for name, effect_settings in pairs(M.config.animations) do
		if not effects_pool[name] then
			effects_pool[name] = Effect.new(effect_settings, effect_settings.effect)
		else
			effects_pool[name]:update_settings(effect_settings)
		end
	end

	AnimationFactory.initialize(M.config, effects_pool, M.config.refresh_interval_ms)

	vim.api.nvim_create_autocmd("TextYankPost", {
		group = animation_group,
		callback = function()
			if not M.config.enabled or vim.v.event.operator == "d" or vim.v.event.operator == "c" then
				return
			end

			local range = utils.get_range_yank()
			local yanked_content = vim.v.event.regcontents

			AnimationFactory.get_instance():create_from_pool(M.config.default_animation, {
				range = range,
				content = yanked_content,
			})
		end,
	})

	if M.config.overwrite.auto_map then
        -- stylua: ignore
        if M.config.overwrite.search.enabled then
            vim.keymap.set("n", "n", "<cmd>lua require('tiny-glimmer').search_next()<CR>",
                { noremap = true, silent = true })
            vim.keymap.set("n", "N", "<cmd>lua require('tiny-glimmer').search_prev()<CR>",
                { noremap = true, silent = true })
            vim.keymap.set("n", "*", "<cmd>lua require('tiny-glimmer').search_under_cursor()<CR>",
                { noremap = true, silent = true })
        end

		if M.config.overwrite.paste.enabled then
			vim.keymap.set("n", "p", "<cmd>lua require('tiny-glimmer').paste()<CR>", { noremap = true, silent = true })
			vim.keymap.set("n", "P", "<cmd>lua require('tiny-glimmer').Paste()<CR>", { noremap = true, silent = true })
		end
		-- stylua: enable
	end

	if M.config.overwrite.search.enabled then
		vim.api.nvim_create_autocmd("CmdlineLeave", {
			group = animation_group,
			callback = function()
				local cmd_type = vim.fn.getcmdtype()
				if cmd_type == "/" or cmd_type == "?" then
					overwrite.search.search_on_line(M.config.overwrite.search)
				end
			end,
		})
		vim.opt.hlsearch = false
	end
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

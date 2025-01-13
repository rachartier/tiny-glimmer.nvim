local M = {}

local utils = require("tiny-glimmer.utils")
local animation_effects = require("tiny-glimmer.effects")

local AnimationEffect = require("tiny-glimmer.animation")

local hl_visual_bg = utils.int_to_hex(utils.get_highlight("CurSearch").bg)
local hl_normal_bg = utils.int_to_hex(utils.get_highlight("Normal").bg)

M.config = {
	enabled = true,
	default_animation = "fade",
	refresh_interval_ms = 6,
	animations = {
		fade = {
			max_duration = 250,
			chars_for_max_duration = 10,
			initial_color = hl_visual_bg,
			final_color = hl_normal_bg,
		},
		bounce = {
			max_duration = 500,
			chars_for_max_duration = 20,
			oscillation_count = 1,
			initial_color = hl_visual_bg,
			final_color = hl_normal_bg,
		},
		left_to_right = {
			max_duration = 350,
			chars_for_max_duration = 40,
			lingering_time = 50,
			initial_color = hl_visual_bg,
			final_color = hl_normal_bg,
		},
		pulse = {
			max_duration = 400,
			chars_for_max_duration = 15,
			pulse_count = 2,
			intensity = 1.2,
			initial_color = hl_visual_bg,
			final_color = hl_normal_bg,
		},
		rainbow = {
			max_duration = 600,
			chars_for_max_duration = 20,
			initial_color = hl_visual_bg,
			final_color = hl_normal_bg,
		},
	},
	virt_text = {
		priority = 2048,
	},
}
local function configure_highlights(options)
	for name, highlight_settings in pairs(options.animations) do
		if highlight_settings.link then
			vim.api.nvim_set_hl(0, name, {
				link = highlight_settings.link,
				default = highlight_settings.default,
			})
		else
			vim.api.nvim_set_hl(0, name, {
				fg = highlight_settings.fg,
				bg = highlight_settings.bg,
				bold = highlight_settings.bold,
				italic = highlight_settings.italic,
				default = highlight_settings.default,
			})
		end
	end
end

function M.setup(options)
	M.config = vim.tbl_deep_extend("force", M.config, options or {})
	configure_highlights(M.config)

	local animation_group = vim.api.nvim_create_augroup("AnimateCopyPaste", { clear = true })

	vim.api.nvim_create_autocmd("TextYankPost", {
		group = animation_group,
		callback = function()
			if not M.config.enabled or vim.v.event.operator == "d" then
				return
			end

			local selection = {
				start_line = vim.fn.line("'[") - 1,
				start_col = vim.fn.col("'[") - 1,
				end_line = vim.fn.line("']") - 1,
				end_col = vim.fn.col("']"),
			}

			local yanked_content = vim.v.event.regcontents

			local animation = AnimationEffect.new(
				M.config.default_animation,
				M.config.animations[M.config.default_animation],
				selection,
				yanked_content
			)

			if animation ~= nil then
				animation:update(M.config.refresh_interval_ms)
			end
		end,
	})
end

vim.api.nvim_create_user_command("TinyGlimmer", function(args)
	local command = args.args
	if command == "enable" then
		M.config.enabled = true
	elseif command == "disable" then
		M.config.enabled = false
	elseif animation_effects[command] then
		M.config.default_animation = command
	else
		vim.notify("Usage: TinyGlimmer [enable|disable|fade|bounce|left_to_right|pulse|rainbow]", vim.log.levels.INFO)
	end
end, {
	nargs = 1,
	complete = function()
		return { "enable", "disable", "fade", "bounce", "left_to_right", "pulse", "rainbow" }
	end,
})

vim.api.nvim_create_user_command("TinyGlimmerTest", function(args)
	local buf_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	for i, line in ipairs(buf_content) do
		if #line > 0 then
			local selection = {
				start_line = i - 1,
				start_col = 0,
				end_line = i - 1,
				end_col = #line,
			}

			local animation_type = "none"
			if line:lower():find("fade") then
				animation_type = "fade"
			elseif line:lower():find("bounce") then
				animation_type = "bounce"
			elseif line:lower():find("left to right") then
				animation_type = "left_to_right"
			elseif line:lower():find("pulse") then
				animation_type = "pulse"
			elseif line:lower():find("rainbow") then
				animation_type = "rainbow"
			end

			if animation_type ~= "none" then
				local animation_config = M.config.animations[animation_type]

				local animation = AnimationEffect.new(animation_type, animation_config, selection, { line })

				if animation ~= nil then
					animation:update(M.config.refresh_interval_ms)
				end
			end
		end
	end
end, { nargs = 0 })

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

return M

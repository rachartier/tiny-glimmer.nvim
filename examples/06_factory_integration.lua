-- Factory Integration Example
-- Register custom effects with the factory during setup()
-- Makes them available globally like built-in effects (fade, pulse, etc.)

local glimmer = require("tiny-glimmer.lib")

-- Register custom effects in setup configuration
-- These effects become available to all animation helper functions
require("tiny-glimmer").setup({
	animations = {
		-- Neon glow effect with pulsing intensity
		neon_glow = {
			max_duration = 800,
			chars_for_max_duration = 20,
			base_color = "#00FF00",
			intensity = 1.5,
			effect = function(self, progress, _ease)
				local hex = self.settings.base_color:gsub("#", "")
				local r = tonumber(hex:sub(1, 2), 16)
				local g = tonumber(hex:sub(3, 4), 16)
				local b = tonumber(hex:sub(5, 6), 16)
				local pulse = math.sin(progress * math.pi)
				local intensity = self.settings.intensity * pulse
				local glow_r = math.min(255, math.floor(r * intensity))
				local glow_g = math.min(255, math.floor(g * intensity))
				local glow_b = math.min(255, math.floor(b * intensity))
				return string.format("#%02x%02x%02x", glow_r, glow_g, glow_b), progress
			end,
		},
		-- Typewriter effect with color transition
		-- Uses builder to pre-parse colors once
		typewriter = {
			max_duration = 1200,
			chars_for_max_duration = 30,
			from_color = "#888888",
			to_color = "#FFFFFF",
			builder = function(self)
				local function hex_to_rgb(hex)
					local h = hex:gsub("#", "")
					return {
						r = tonumber(h:sub(1, 2), 16),
						g = tonumber(h:sub(3, 4), 16),
						b = tonumber(h:sub(5, 6), 16),
					}
				end
				return {
					initial = hex_to_rgb(self.settings.from_color),
					final = hex_to_rgb(self.settings.to_color),
				}
			end,
			effect = function(self, progress, _ease)
				local start = self.starter.initial
				local finish = self.starter.final
				local r = math.floor(start.r + (finish.r - start.r) * progress)
				local g = math.floor(start.g + (finish.g - start.g) * progress)
				local b = math.floor(start.b + (finish.b - start.b) * progress)
				return string.format("#%02x%02x%02x", r, g, b), progress
			end,
		},
		-- Fire effect with gradient and flicker
		fire = {
			max_duration = 1000,
			chars_for_max_duration = 25,
			effect = function(_self, progress, _ease)
				local colors = {
					{ r = 255, g = 255, b = 100 },
					{ r = 255, g = 150, b = 0 },
					{ r = 255, g = 50, b = 0 },
					{ r = 100, g = 0, b = 0 },
				}
				local flicker = (math.sin(progress * 50) + 1) / 2 * 0.2
				local segment_count = #colors - 1
				local segment = math.floor(progress * segment_count)
				segment = math.min(segment, segment_count - 1)
				local local_progress = (progress * segment_count) - segment + flicker
				local_progress = math.max(0, math.min(1, local_progress))
				local start = colors[segment + 1]
				local finish = colors[segment + 2]
				local r = math.floor(start.r + (finish.r - start.r) * local_progress)
				local g = math.floor(start.g + (finish.g - start.g) * local_progress)
				local b = math.floor(start.b + (finish.b - start.b) * local_progress)
				return string.format("#%02x%02x%02x", r, g, b), progress
			end,
		},
	},
})

-- Use registered custom effects with helper functions
vim.keymap.set("n", "<leader>agn", function()
	glimmer.cursor_line("neon_glow")
end, { desc = "Animate cursor line with neon glow effect" })

vim.keymap.set("n", "<leader>agt", function()
	glimmer.cursor_line("typewriter")
end, { desc = "Animate cursor line with typewriter effect" })

vim.keymap.set("n", "<leader>agf", function()
	glimmer.cursor_line("fire")
end, { desc = "Animate cursor line with fire effect" })

vim.keymap.set("v", "<leader>agn", function()
	glimmer.visual_selection("neon_glow")
end, { desc = "Animate selection with neon glow" })

-- Override registered effect settings at runtime
-- Pass table with name and settings to customize behavior
vim.keymap.set("n", "<leader>agc", function()
	glimmer.cursor_line({
		name = "neon_glow",
		settings = {
			base_color = "#FF00FF",
			intensity = 2.0,
			max_duration = 500,
		},
	})
end, { desc = "Custom neon glow with purple color" })

-- Alternative syntax: pass settings as second argument
vim.keymap.set("n", "<leader>agc2", function()
	glimmer.cursor_line("neon_glow", {
		base_color = "#0000FF",
		intensity = 3.0,
	})
end, { desc = "Another way to override settings" })

-- Use custom effects in autocmds
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("CustomFireYank", { clear = true }),
	callback = function()
		local range = glimmer.get_yank_range()
		if range then
			glimmer.animate_range("fire", range)
		end
	end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
	group = vim.api.nvim_create_augroup("CustomTypewriter", { clear = true }),
	callback = function()
		glimmer.cursor_line("typewriter")
	end,
})

-- Named animations with custom effects for manual control
vim.keymap.set("n", "<leader>ans", function()
	local line = vim.fn.line(".")
	local range = {
		start_line = line - 1,
		start_col = 0,
		end_line = line,
		end_col = 0,
	}
	glimmer.named_animate_range("my_custom_anim", "neon_glow", range)
end, { desc = "Start named neon glow animation" })

vim.keymap.set("n", "<leader>anx", function()
	glimmer.stop_animation("my_custom_anim")
end, { desc = "Stop named animation" })

-- Create a library of custom effects
local custom_effects = {
	matrix = {
		max_duration = 1500,
		chars_for_max_duration = 40,
		effect = function(_self, progress)
			local green_intensity = math.floor(255 * (1 - progress))
			return string.format("#00%02x00", green_intensity), progress
		end,
	},
	glitch = {
		max_duration = 600,
		chars_for_max_duration = 20,
		effect = function(_self, progress)
			local glitch_value = math.floor(progress * 100) % 3
			if glitch_value == 0 then
				return "#FF00FF", progress
			elseif glitch_value == 1 then
				return "#00FFFF", progress
			else
				return "#FFFF00", progress
			end
		end,
	},
	ocean = {
		max_duration = 2000,
		chars_for_max_duration = 50,
		effect = function(_self, progress)
			local wave = (math.sin(progress * math.pi * 4) + 1) / 2
			local blue = math.floor(100 + wave * 155)
			local green = math.floor(150 + wave * 105)
			return string.format("#00%02x%02x", green, blue), progress
		end,
	},
}

-- Register all custom effects at once
require("tiny-glimmer").setup({
	animations = vim.tbl_extend("force", {}, custom_effects),
})

-- Auto-generate keymaps for all effects
for effect_name, _ in pairs(custom_effects) do
	vim.keymap.set("n", "<leader>ae" .. effect_name:sub(1, 1), function()
		glimmer.cursor_line(effect_name)
	end, { desc = "Animate with " .. effect_name .. " effect" })
end

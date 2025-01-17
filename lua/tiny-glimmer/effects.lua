local utils = require("tiny-glimmer.utils")
local easing_functions = require("tiny-glimmer.easing")

return {
	fade = function(self, from, to, progress, ease)
		local initial = utils.hex_to_rgb(from)
		local final = utils.hex_to_rgb(to)
		local current = {}

		local fn = easing_functions[ease]

		current = {
			r = fn(progress, initial.r, final.r - initial.r, 1),
			g = fn(progress, initial.g, final.g - initial.g, 1),
			b = fn(progress, initial.b, final.b - initial.b, 1),
		}

		return utils.rgb_to_hex(current), 1
	end,
	reverse_fade = function(self, from, to, progress, ease)
		local initial = utils.hex_to_rgb(from)
		local final = utils.hex_to_rgb(to)

		local fn = easing_functions[ease]

		local current = {
			r = fn(progress, final.r, initial.r - final.r, 1),
			g = fn(progress, final.g, initial.g - final.g, 1),
			b = fn(progress, final.b, initial.b - final.b, 1),
		}

		return utils.rgb_to_hex(current), 1
	end,
	bounce = function(self, from, to, progress)
		local oscillation = math.abs(math.sin(progress * math.pi * self.settings.oscillation_count))

		local initial = utils.hex_to_rgb(from)
		local final = utils.hex_to_rgb(to)

		local current = {
			r = math.max(initial.r + (final.r - initial.r) * oscillation, 0),
			g = math.max(initial.g + (final.g - initial.g) * oscillation, 0),
			b = math.max(initial.b + (final.b - initial.b) * oscillation, 0),
		}

		return utils.rgb_to_hex(current), 1
	end,

	left_to_right = function(self, from, to, progress)
		local initial = utils.hex_to_rgb(from)
		local final = utils.hex_to_rgb(to)

		local current = {
			r = initial.r + (final.r - initial.r) * math.min(0.9, progress),
			g = initial.g + (final.g - initial.g) * math.min(0.9, progress),
			b = initial.b + (final.b - initial.b) * math.min(0.9, progress),
		}

		return utils.rgb_to_hex(current), progress
	end,
	pulse = function(self, from, to, progress)
		local initial = utils.hex_to_rgb(from)
		local final = utils.hex_to_rgb(to)

		local pulse = math.abs(math.sin(progress * math.pi * self.settings.pulse_count))
		pulse = pulse * self.settings.intensity

		local current = {
			r = math.min(255, initial.r + (final.r - initial.r) * progress + pulse * 50),
			g = math.min(255, initial.g + (final.g - initial.g) * progress + pulse * 50),
			b = math.min(255, initial.b + (final.b - initial.b) * progress + pulse * 50),
		}

		return utils.rgb_to_hex(current), 1
	end,

	rainbow = function(self, from, to, progress)
		local rainbow_colors = {
			{ r = 255, g = 0, b = 0 },
			{ r = 255, g = 127, b = 0 },
			{ r = 255, g = 255, b = 0 },
			{ r = 0, g = 255, b = 0 },
			{ r = 0, g = 0, b = 255 },
			{ r = 75, g = 0, b = 130 },
			{ r = 148, g = 0, b = 211 },
		}

		local index = math.floor(progress * (#rainbow_colors - 1)) + 1
		local next_index = math.min(index + 1, #rainbow_colors)
		local color_progress = (progress * (#rainbow_colors - 1)) % 1

		local current = {
			r = rainbow_colors[index].r + (rainbow_colors[next_index].r - rainbow_colors[index].r) * color_progress,
			g = rainbow_colors[index].g + (rainbow_colors[next_index].g - rainbow_colors[index].g) * color_progress,
			b = rainbow_colors[index].b + (rainbow_colors[next_index].b - rainbow_colors[index].b) * color_progress,
		}

		return utils.rgb_to_hex(current), 1
	end,
}

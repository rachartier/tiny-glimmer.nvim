-- lua/animate-copy-paste/init.lua
local M = {}

-- Configuration par défaut
M.config = {
	enabled = true,
	default_animation = "left_to_right",
	update_ms = 1,
	animations = {
		fade = {
			duration = 250,
			start_color = "#8087a2",
			end_color = "#24273a",
		},
		bounce = {
			duration = 500,
			start_color = "#8087a2",
			end_color = "#24273a",
			bounce_count = 1,
		},
		left_to_right = {
			duration = 150,
			start_color = "#8087a2",
			end_color = "#363a4f",
			overstay = 50,
		},
	},
	virt_text = {
		priority = 2048,
	},
}

-- Namespace pour les extmarks
local ns_id = vim.api.nvim_create_namespace("animate_copy_paste")

local function get_hl(name)
	local hl = vim.api.nvim_get_hl(0, {
		name = name,
		link = false,
	})

	return {
		fg = hl.fg,
		bg = hl.bg,
		bold = hl.bold or false,
		italic = hl.italic or false,
	}
end

-- Gestionnaire d'animations
local Animation = {}
Animation.__index = Animation

function Animation.new(type, opts, region)
	local self = setmetatable({}, Animation)
	self.type = type
	self.opts = opts
	self.region = region
	self.start_time = vim.loop.now()
	self.is_running = true
	self.regcontents = vim.v.event.regcontents or {}
	self.regtype = vim.v.event.regtype
	self.operator = vim.v.event.operator
	self.hl_visual = get_hl("Visual")
	self.virt_text = opts.virt_text or {}
	return self
end

local function setup_highlights(opts)
	local animation = opts.animations

	for group_name, settings in pairs(animation) do
		if settings.link then
			vim.api.nvim_set_hl(0, group_name, {
				link = settings.link,
				default = settings.default,
			})
		else
			vim.api.nvim_set_hl(0, group_name, {
				fg = settings.fg,
				bg = settings.bg,
				bold = settings.bold,
				italic = settings.italic,
				default = settings.default,
			})
		end
	end
end

-- Animations disponibles
local animations = {
	fade = function(self, progress)
		local start_rgb = self:hex_to_rgb(self.opts.start_color)
		local end_rgb = self:hex_to_rgb(self.opts.end_color)

		local current_rgb = {
			r = start_rgb.r + (end_rgb.r - start_rgb.r) * progress,
			g = start_rgb.g + (end_rgb.g - start_rgb.g) * progress,
			b = start_rgb.b + (end_rgb.b - start_rgb.b) * progress,
		}

		return self:rgb_to_hex(current_rgb), 1
	end,

	bounce = function(self, progress)
		local bounce_progress = math.abs(math.sin(progress * math.pi * self.opts.bounce_count))

		local start_rgb = self:hex_to_rgb(self.opts.start_color)
		local end_rgb = self:hex_to_rgb(self.opts.end_color)

		local current_rgb = {
			r = math.max(start_rgb.r + (end_rgb.r - start_rgb.r) * bounce_progress, 0),
			g = math.max(start_rgb.g + (end_rgb.g - start_rgb.g) * bounce_progress, 0),
			b = math.max(start_rgb.b + (end_rgb.b - start_rgb.b) * bounce_progress, 0),
		}

		return self:rgb_to_hex(current_rgb), 1
	end,

	left_to_right = function(self, progress)
		local start_rgb = self:hex_to_rgb(self.opts.start_color)
		local end_rgb = self:hex_to_rgb(self.opts.end_color)

		local current_rgb = {
			r = start_rgb.r + (end_rgb.r - start_rgb.r) * progress,
			g = start_rgb.g + (end_rgb.g - start_rgb.g) * progress,
			b = start_rgb.b + (end_rgb.b - start_rgb.b) * progress,
		}

		return self:rgb_to_hex(current_rgb), progress
	end,
}

-- Utilitaires pour la conversion des couleurs
function Animation:hex_to_rgb(hex)
	if hex == "NONE" then
		return { r = 0, g = 0, b = 0 }
	end
	hex = hex:gsub("#", "")
	return {
		r = tonumber(hex:sub(1, 2), 16),
		g = tonumber(hex:sub(3, 4), 16),
		b = tonumber(hex:sub(5, 6), 16),
	}
end

function Animation:rgb_to_hex(rgb)
	return string.format("#%02X%02X%02X", rgb.r, rgb.g, rgb.b)
end

-- Mise à jour de l'animation
function Animation:update()
	if not self.is_running then
		return
	end

	local current_time = vim.loop.now()
	local elapsed = current_time - self.start_time
	local progress = math.min(elapsed / self.opts.duration, 1)

	local color, animation_progress = animations[self.type](self, progress)

	vim.api.nvim_set_hl(0, "UpdateColor", {
		bg = color,
	})

	vim.api.nvim_buf_clear_namespace(0, ns_id, self.region.start_line, self.region.end_line + 1)

	local text_to_animate = {}

	for i, line in ipairs(self.regcontents) do
		local end_col = #line * animation_progress
		if self.regtype:lower() == "v" then
			local subline
			if i == 1 then
				if self.region.end_line == self.region.start_line then
					end_col = self.region.end_col * animation_progress
				end
				subline = line:sub(1, end_col)
			elseif i == #self.regcontents then
				subline = line:sub(1, self.region.end_col * animation_progress)
			else
				subline = line:sub(1, end_col)
			end
			table.insert(text_to_animate, {
				line = i - 1,
				start_col = (i == 1) and self.region.start_col or 0,
				end_col = (i == #self.regcontents) and self.region.end_col or end_col,
				virt_text = { subline, "UpdateColor" },
			})
		else
			table.insert(text_to_animate, {
				line = i - 1,
				start_col = self.region.start_col,
				end_col = end_col,
				virt_text = { line, "UpdateColor" },
			})
		end
	end

	for _, line in ipairs(text_to_animate) do
		local end_col_animation = math.ceil(line.end_col * animation_progress)
		if end_col_animation < line.start_col then
			end_col_animation = line.start_col
		elseif end_col_animation == 0 then
			end_col_animation = 1
		end

		vim.api.nvim_buf_set_extmark(0, ns_id, self.region.start_line + line.line, line.start_col, {
			end_col = end_col_animation,
			hl_group = "UpdateColor",
			hl_mode = "blend",
			priority = self.virt_text.priority or 1000,
			strict = false,
		})
	end

	if progress >= 1 then
		self.is_running = false
		vim.defer_fn(function()
			vim.api.nvim_buf_clear_namespace(0, ns_id, self.region.start_line, self.region.end_line + 1)
		end, self.opts.overstay or 0)
	else
		vim.defer_fn(function()
			self:update()
		end, M.config.update_ms)
	end
end

-- API principale
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	-- Configure les highlight groups
	setup_highlights(M.config)

	local group = vim.api.nvim_create_augroup("AnimateCopyPaste", { clear = true })

	vim.api.nvim_create_autocmd("TextYankPost", {
		group = group,
		callback = function()
			if not M.config.enabled then
				return
			end

			if vim.v.event.operator == "d" then
				return
			end

			local region = {
				start_line = vim.fn.line("'[") - 1,
				start_col = vim.fn.col("'[") - 1,
				end_line = vim.fn.line("']") - 1,
				end_col = vim.fn.col("']"),
			}

			local animation =
				Animation.new(M.config.default_animation, M.config.animations[M.config.default_animation], region)
			animation:update()
		end,
	})
end

-- Commande pour tester les animations
vim.api.nvim_create_user_command("AnimateCopyPaste", function(opts)
	local args = opts.args
	if args == "enable" then
		M.config.enabled = true
	elseif args == "disable" then
		M.config.enabled = false
	elseif animations[args] then
		M.config.default_animation = args
	else
		print("Usage: AnimateCopyPaste [enable|disable|fade|bounce|left_to_right]")
	end
end, {
	nargs = 1,
	complete = function()
		return { "enable", "disable", "fade", "bounce", "left_to_right" }
	end,
})

return M

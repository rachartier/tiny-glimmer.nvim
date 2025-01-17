---@class Effect
---@field settings table
---@field update_fn function

local Effect = {}
Effect.__index = Effect

function Effect.new(settings, update_fn)
	local self = setmetatable({}, Effect)

	self.settings = settings
	self.update_fn = update_fn

	return self
end

function Effect.update_settings(self, settings)
	self.settings = settings
end

return Effect

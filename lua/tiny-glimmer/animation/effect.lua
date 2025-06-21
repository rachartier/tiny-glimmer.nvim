---@class Effect
---@field settings table
---@field update_fn function
---@field build_starter function
---@field starter table

local Effect = {}
Effect.__index = Effect

function Effect.new(settings, update_fn, builder)
  local self = setmetatable({}, Effect)

  self.settings = settings
  self.update_fn = update_fn

  self._starter_builder = builder

  return self
end

function Effect:build_starter()
  if self._starter_builder then
    self.starter = self._starter_builder(self)
  end
end

function Effect:update_settings(settings)
  self.settings = settings
end

return Effect

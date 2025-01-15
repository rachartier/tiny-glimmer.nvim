local AnimationFactory = {}
AnimationFactory.__index = AnimationFactory

local instance = nil
local AnimationEffect = require("tiny-glimmer.animation")

function AnimationFactory.initialize(opts, animations, animation_refresh)
	if instance then
		vim.notify("TinyGlimmer: AnimationFactory is already initialized.", vim.log.levels.WARN)
		return
	end

	instance = setmetatable({}, AnimationFactory)
	instance.settings = opts or {}
	instance.animations = animations or {}
	instance.animation_refresh = animation_refresh or 0
end

function AnimationFactory.get_instance()
	if not instance then
		vim.notify("TinyGlimmer: AnimationFactory is not initialized.", vim.log.levels.ERROR)
	end
	return instance
end

function AnimationFactory:create(animation_type, selection, content)
	if not self.animations[animation_type] then
		vim.notify("TinyGlimmer: Invalid animation type: " .. animation_type, vim.log.levels.ERROR)
		return
	end

	local animation, error_msg =
		AnimationEffect.new(animation_type, self.animations[animation_type], selection, content)

	if animation then
		animation:update(self.animation_refresh)
	else
		vim.notify("TinyGlimmer: " .. error_msg, vim.log.levels.ERROR)
	end
end

return AnimationFactory

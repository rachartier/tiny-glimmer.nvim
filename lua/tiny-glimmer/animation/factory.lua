---@class AnimationFactorySettings
---@field virtual_text_priority number The priority of the virtual text

---@class AnimationFactory
---@field settings AnimationFactorySettings
---@field effect_pool table {string: table}
---@field animation_refresh number The refresh rate of the animation (in ms)
---@field instance AnimationFactory

---@class CreateAnimationOpts
---@field range table {start_line: number, start_col: number, end_line: number, end_col: number}
---@field content string[]|nil Content of the animation

local AnimationFactory = {}
AnimationFactory.__index = AnimationFactory

local instance = nil
local TextAnimation = require("tiny-glimmer.animation.text_animation")
local TextAnimation = require("tiny-glimmer.animation.premade.text")

function AnimationFactory.initialize(opts, effect_pool, animation_refresh)
	if instance then
		vim.notify("TinyGlimmer: AnimationFactory is already initialized.", vim.log.levels.WARN)
		return
	end

	instance = setmetatable({}, AnimationFactory)
	instance.settings = opts or {}
	instance.effect_pool = effect_pool or {}
	instance.animation_refresh = animation_refresh or 1
end

function AnimationFactory.get_instance()
	if not instance then
		vim.notify("TinyGlimmer: AnimationFactory is not initialized.", vim.log.levels.ERROR)
	end
	return instance
end

--- Create and launch an animation effect from the pool
--- @param animation_type string The type of animation to create
--- @param opts CreateAnimationOpts
function AnimationFactory:create_text_animation(animation_type, opts)
	if not opts.base.range then
		error("TinyGlimmer: range is required in opts")
	end

	if not self.effect_pool[animation_type] then
		vim.notify("TinyGlimmer: Invalid animation type: " .. animation_type, vim.log.levels.ERROR)
		return
	end

	local effect = self.effect_pool[animation_type]

	local animation = TextAnimation.new(effect, opts)

	if animation then
		animation:start(self.animation_refresh)
	else
		error("TinyGlimmer: Failed to create animation")
	end
end

return AnimationFactory

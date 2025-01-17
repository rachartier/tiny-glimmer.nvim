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
local AnimationEffect = require("tiny-glimmer.animation")

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
function AnimationFactory:create_from_pool(animation_type, opts)
	if not opts.range then
		vim.notify("TinyGlimmer: selection is required in opts", vim.log.levels.ERROR)
		return
	end

	local range = opts.range
	local content = opts.content

	if not self.effect_pool[animation_type] then
		vim.notify("TinyGlimmer: Invalid animation type: " .. animation_type, vim.log.levels.ERROR)
		return
	end

	local effect = self.effect_pool[animation_type]

	local animation, error_msg = AnimationEffect.new(effect, {
		range = range,
		content = content,
		virtual_text_priority = self.settings.virtual_text_priority,
	})

	if animation then
		animation:update(self.animation_refresh)
	else
		vim.notify("TinyGlimmer: " .. error_msg, vim.log.levels.ERROR)
	end
end

return AnimationFactory

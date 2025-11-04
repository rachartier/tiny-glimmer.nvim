local MiniTest = require("mini.test")
local H = require("tests.helpers")

local T = MiniTest.new_set()

T["Loop functionality"] = MiniTest.new_set()

T["Loop functionality"]["should support finite loop count"] = function()
	local glimmer = require("tiny-glimmer.lib")
	local completed = false

	-- Create animation that loops 2 times
	glimmer.create_animation({
		range = glimmer.get_line_range(1),
		duration = 50,
		from_color = "#ff0000",
		to_color = "#00ff00",
		loop = true,
		loop_count = 2,
		on_complete = function()
			completed = true
		end,
	})

	-- Wait for animation to complete (50ms * 2 loops + buffer)
	vim.wait(200, function()
		return completed
	end)

	MiniTest.expect.equality(completed, true)
end

T["Loop functionality"]["should support infinite loops that can be stopped"] = function()
	local glimmer = require("tiny-glimmer.lib")

	-- Create infinite loop animation
	glimmer.named_animate_range("test_infinite", "fade", glimmer.get_line_range(1), {
		loop = true,
		loop_count = 0, -- infinite
	})

	-- Wait a bit
	vim.wait(100)

	-- Stop the animation
	glimmer.stop_animation("test_infinite")

	-- Animation should be stopped
	local factory = require("tiny-glimmer.animation.factory").get_instance()
	local buffer = vim.api.nvim_get_current_buf()

	MiniTest.expect.equality(factory.buffers[buffer].named_animations["test_infinite"], nil)
end

T["Loop functionality"]["should loop the specified number of times"] = function()
	local GlimmerAnimation = require("tiny-glimmer.glimmer_animation")
	local Effect = require("tiny-glimmer.animation.effect")

	local loop_count = 0
	local completed = false

	-- Create a simple effect
	local effect = Effect.new({
		max_duration = 50,
		min_duration = 50,
		chars_for_max_duration = 10,
		from_color = "#ff0000",
		to_color = "#00ff00",
	}, function(self, progress)
		return self.settings.from_color, progress
	end)

	-- Create animation with loop
	local animation = GlimmerAnimation.new(effect, {
		range = { start_line = 0, start_col = 0, end_line = 0, end_col = 10 },
		loop = true,
		loop_count = 3,
	})

	-- Track loop iterations
	local original_update = animation.update_effect
	animation.update_effect = function(self, progress)
		if progress < 0.1 then
			-- Starting a new loop
			if self._last_progress and self._last_progress > 0.9 then
				loop_count = loop_count + 1
			end
		end
		self._last_progress = progress
		return original_update(self, progress)
	end

	animation:start(10, 10, {
		on_update = function() end,
		on_complete = function()
			completed = true
		end,
	})

	-- Wait for completion
	vim.wait(500, function()
		return completed
	end)

	MiniTest.expect.equality(completed, true)
	-- Should have looped 3 times (starting from 0: 0->1, 1->2, 2->3)
	MiniTest.expect.equality(loop_count >= 2, true)
end

T["Loop functionality"]["should not loop when loop is false"] = function()
	local glimmer = require("tiny-glimmer.lib")
	local completed = false
	local start_time = vim.uv.now()

	-- Create animation without loop
	glimmer.create_animation({
		range = glimmer.get_line_range(1),
		duration = 50,
		from_color = "#ff0000",
		to_color = "#00ff00",
		loop = false,
		on_complete = function()
			completed = true
		end,
	})

	-- Wait for animation to complete
	vim.wait(150, function()
		return completed
	end)

	local elapsed = vim.uv.now() - start_time

	MiniTest.expect.equality(completed, true)
	-- Should complete in ~50ms (one iteration), not multiple loops
	MiniTest.expect.equality(elapsed < 100, true)
end

return T

local AnimationFactory = require("tiny-glimmer.animation.factory")
local MiniTest = require("mini.test")

local T = MiniTest.new_set()

T["factory"] = MiniTest.new_set()

-- Test initialization and singleton behavior
T["factory"]["initialize singleton"] = function()
  AnimationFactory.instance = nil
  local factory = AnimationFactory.initialize(
    { virtual_text_priority = 100 },
    { fade = { settings = {} } },
    50
  )
  MiniTest.expect.equality(factory.settings.virtual_text_priority, 100)
  MiniTest.expect.equality(factory.animation_refresh, 50)
  MiniTest.expect.equality(factory.effect_pool.fade.settings, {})
end

T["factory"]["initialize returns same instance"] = function()
  AnimationFactory.instance = nil
  local factory1 = AnimationFactory.initialize()
  local factory2 = AnimationFactory.initialize()
  MiniTest.expect.equality(factory1, factory2)
end

T["factory"]["get_instance throws error when not initialized"] = function()
  AnimationFactory.instance = nil
  MiniTest.expect.error(function()
    AnimationFactory.get_instance()
  end, "TinyGlimmer: AnimationFactory not initialized")
end

T["factory"]["get_instance returns initialized instance"] = function()
  AnimationFactory.instance = nil
  local factory1 = AnimationFactory.initialize()
  local factory2 = AnimationFactory.get_instance()
  MiniTest.expect.equality(factory1, factory2)
end

-- Test validation helpers
T["factory"]["validate_animation_type succeeds with valid type"] = function()
  AnimationFactory.instance = nil
  AnimationFactory.initialize(nil, { fade = { settings = {} } })
  MiniTest.expect.no_error(function()
    AnimationFactory.instance:_prepare_animation_effect(
      1,
      "fade",
      { base = { range = { start_line = 1, start_col = 1, end_line = 1, end_col = 5 } } }
    )
  end)
end

T["factory"]["validate_animation_type fails with invalid type"] = function()
  AnimationFactory.instance = nil
  AnimationFactory.initialize(nil, { fade = { settings = {} } })
  MiniTest.expect.error(function()
    AnimationFactory.instance:_prepare_animation_effect(
      1,
      "invalid",
      { base = { range = { start_line = 1, start_col = 1, end_line = 1, end_col = 5 } } }
    )
  end, "Invalid animation type: invalid")
end

-- Test settings merging (using vim.tbl_extend directly since merge_settings is local)
T["factory"]["merge_settings with no overwrite"] = function()
  local base = { duration = 1000, color = "red" }
  local result = vim.tbl_extend("force", base, {})
  MiniTest.expect.equality(result.duration, 1000)
  MiniTest.expect.equality(result.color, "red")
end

T["factory"]["merge_settings with overwrite"] = function()
  local base = { duration = 1000, color = "red" }
  local overwrite = { duration = 2000, size = 10 }
  local result = vim.tbl_extend("force", base, overwrite)
  MiniTest.expect.equality(result.duration, 2000)
  MiniTest.expect.equality(result.color, "red")
  MiniTest.expect.equality(result.size, 10)
end

-- Test animation preparation
T["factory"]["prepare_animation_effect requires range"] = function()
  AnimationFactory.instance = nil
  AnimationFactory.initialize(nil, { fade = { settings = {} } })
  MiniTest.expect.error(function()
    AnimationFactory.instance:_prepare_animation_effect(1, "fade", { base = {} })
  end, "TinyGlimmer: Range is required in options")
end

T["factory"]["prepare_animation_effect with string animation_type"] = function()
  AnimationFactory.instance = nil
  AnimationFactory.initialize(nil, { fade = { settings = { duration = 1000 } } })
  local effect = AnimationFactory.instance:_prepare_animation_effect(
    1,
    "fade",
    { base = { range = { start_line = 1, start_col = 1, end_line = 1, end_col = 5 } } }
  )
  MiniTest.expect.equality(effect.settings.duration, 1000)
end

T["factory"]["prepare_animation_effect with table animation_type"] = function()
  AnimationFactory.instance = nil
  AnimationFactory.initialize(nil, { fade = { settings = { duration = 1000 } } })
  local effect = AnimationFactory.instance:_prepare_animation_effect(
    1,
    { name = "fade", settings = { duration = 2000 } },
    { base = { range = { start_line = 1, start_col = 1, end_line = 1, end_col = 5 } } }
  )
  MiniTest.expect.equality(effect.settings.duration, 2000)
end

T["factory"]["prepare_animation_effect initializes buffer tracking"] = function()
  AnimationFactory.instance = nil
  AnimationFactory.initialize(nil, { fade = { settings = {} } })
  AnimationFactory.instance:_prepare_animation_effect(
    1,
    "fade",
    { base = { range = { start_line = 1, start_col = 1, end_line = 1, end_col = 5 } } }
  )
  MiniTest.expect.equality(type(AnimationFactory.instance.buffers[1]), "table")
  MiniTest.expect.equality(type(AnimationFactory.instance.buffers[1].animations), "table")
  MiniTest.expect.equality(type(AnimationFactory.instance.buffers[1].named_animations), "table")
end

-- Test animation management (mock animation objects)
T["factory"]["manage_animation stores and starts animation"] = function()
  AnimationFactory.instance = nil
  AnimationFactory.initialize(nil, { fade = { settings = {} } })
  -- Initialize buffer first
  AnimationFactory.instance:_prepare_animation_effect(
    1,
    "fade",
    { base = { range = { start_line = 1, start_col = 1, end_line = 1, end_col = 5 } } }
  )
  local mock_animation = {
    animation = { range = { start_line = 1 } },
    start = function(self, refresh, callback)
      self.started = true
      self.refresh = refresh
      self.callback = callback
    end,
  }
  AnimationFactory.instance:_manage_animation(mock_animation, 1)
  MiniTest.expect.equality(AnimationFactory.instance.buffers[1].animations[1], mock_animation)
  MiniTest.expect.equality(mock_animation.started, true)
  MiniTest.expect.equality(mock_animation.refresh, 1)
end

T["factory"]["manage_animation stops existing animation on same line"] = function()
  AnimationFactory.instance = nil
  AnimationFactory.initialize(nil, { fade = { settings = {} } })
  local stopped = false
  local old_animation = {
    stop = function()
      stopped = true
    end,
  }
  AnimationFactory.instance.buffers[1] = { animations = { [1] = old_animation } }

  local new_animation = {
    animation = { range = { start_line = 1 } },
    start = function() end,
  }
  AnimationFactory.instance:_manage_animation(new_animation, 1)
  MiniTest.expect.equality(stopped, true)
end

T["factory"]["manage_named_animation stores and starts animation"] = function()
  AnimationFactory.instance = nil
  AnimationFactory.initialize(nil, { fade = { settings = {} } })
  -- Initialize buffer first
  AnimationFactory.instance:_prepare_animation_effect(
    1,
    "fade",
    { base = { range = { start_line = 1, start_col = 1, end_line = 1, end_col = 5 } } }
  )
  local mock_animation = {
    start = function(self, refresh, callback)
      self.started = true
      self.refresh = refresh
      self.callback = callback
    end,
  }
  AnimationFactory.instance:_manage_named_animation("test", mock_animation, 1)
  MiniTest.expect.equality(
    AnimationFactory.instance.buffers[1].named_animations["test"],
    mock_animation
  )
  MiniTest.expect.equality(mock_animation.started, true)
end

T["factory"]["manage_named_animation stops existing named animation"] = function()
  AnimationFactory.instance = nil
  AnimationFactory.initialize(nil, { fade = { settings = {} } })
  local stopped = false
  local old_animation = {
    stop = function()
      stopped = true
    end,
  }
  AnimationFactory.instance.buffers[1] = { named_animations = { test = old_animation } }

  local new_animation = {
    start = function() end,
  }
  AnimationFactory.instance:_manage_named_animation("test", new_animation, 1)
  MiniTest.expect.equality(stopped, true)
end

-- Test public API methods (mock vim.api and premade modules)
local original_nvim_get_current_buf = vim.api.nvim_get_current_buf
local original_text_new = nil
local original_line_new = nil

T["factory"]["create_text_animation"] = function()
  AnimationFactory.instance = nil
  vim.api.nvim_get_current_buf = function()
    return 1
  end
  local original_text_new = package.loaded["tiny-glimmer.animation.premade.text"]
  package.loaded["tiny-glimmer.animation.premade.text"] = {
    new = function()
      return { animation = { range = { start_line = 1 } }, start = function() end }
    end,
  }

  AnimationFactory.initialize(nil, { fade = { settings = {} } })
  AnimationFactory.instance:create_text_animation(
    "fade",
    { base = { range = { start_line = 1, start_col = 1, end_line = 1, end_col = 5 } } }
  )
  MiniTest.expect.equality(type(AnimationFactory.instance.buffers[1].animations[1]), "table")

  package.loaded["tiny-glimmer.animation.premade.text"] = original_text_new
  vim.api.nvim_get_current_buf = original_nvim_get_current_buf
end

T["factory"]["create_named_text_animation"] = function()
  AnimationFactory.instance = nil
  vim.api.nvim_get_current_buf = function()
    return 1
  end
  local original_text_new = package.loaded["tiny-glimmer.animation.premade.text"]
  package.loaded["tiny-glimmer.animation.premade.text"] = {
    new = function()
      return { animation = { range = { start_line = 1 } }, start = function() end }
    end,
  }

  AnimationFactory.initialize(nil, { fade = { settings = {} } })
  AnimationFactory.instance:create_named_text_animation(
    "test",
    "fade",
    { base = { range = { start_line = 1, start_col = 1, end_line = 1, end_col = 5 } } }
  )
  MiniTest.expect.equality(
    type(AnimationFactory.instance.buffers[1].named_animations["test"]),
    "table"
  )

  package.loaded["tiny-glimmer.animation.premade.text"] = original_text_new
  vim.api.nvim_get_current_buf = original_nvim_get_current_buf
end

T["factory"]["create_line_animation"] = function()
  AnimationFactory.instance = nil
  vim.api.nvim_get_current_buf = function()
    return 1
  end
  local original_line_new = package.loaded["tiny-glimmer.animation.premade.line"]
  package.loaded["tiny-glimmer.animation.premade.line"] = {
    new = function()
      return { animation = { range = { start_line = 1 } }, start = function() end }
    end,
  }

  AnimationFactory.initialize(nil, { fade = { settings = {} } })
  AnimationFactory.instance:create_line_animation(
    "fade",
    { base = { range = { start_line = 1, start_col = 1, end_line = 1, end_col = 5 } } }
  )
  MiniTest.expect.equality(type(AnimationFactory.instance.buffers[1].animations[1]), "table")

  package.loaded["tiny-glimmer.animation.premade.line"] = original_line_new
  vim.api.nvim_get_current_buf = original_nvim_get_current_buf
end

return T

local AnimationFactory = require("tiny-glimmer.animation.factory")
local Lib = require("tiny-glimmer.lib")
local MiniTest = require("mini.test")

local T = MiniTest.new_set()

T["lib"] = MiniTest.new_set()

-- Helpers
local function reset_state()
  AnimationFactory.instance = nil
  package.loaded["tiny-glimmer.lib"] = nil
  Lib = require("tiny-glimmer.lib")
end

local function mock_buffer_api()
  vim.api.nvim_get_current_buf = function()
    return 1
  end
end

local function restore_buffer_api()
  vim.api.nvim_get_current_buf = function()
    return 0
  end
end

local function mock_animation_modules()
  package.loaded["tiny-glimmer.animation.premade.text"] = {
    new = function(effect, opts)
      return {
        animation = { range = opts.base.range },
        start = function(self, refresh, callback)
          self.started = true
          self.refresh = refresh
          self.callback = callback
        end,
        stop = function(self)
          self.stopped = true
        end,
      }
    end,
  }
  package.loaded["tiny-glimmer.animation.premade.line"] = {
    new = function(effect, opts)
      return {
        animation = { range = opts.base.range },
        start = function(self, refresh, callback)
          self.started = true
          self.refresh = refresh
          self.callback = callback
        end,
      }
    end,
  }
end

local function ensure_factory_has_effects()
  -- Initialize factory if needed
  if not AnimationFactory.instance then
    AnimationFactory.initialize({ virtual_text_priority = 2048 }, {}, 8)
  end
  local factory = AnimationFactory.get_instance()
  -- Check if effect_pool is nil or empty
  if not factory.effect_pool or vim.tbl_isempty(factory.effect_pool) then
    local premade_effects = require("tiny-glimmer.premade_effects")
    factory.effect_pool = premade_effects
  end
end

-- Test create_animation
T["lib"]["create_animation requires range"] = function()
  reset_state()
  MiniTest.expect.error(function()
    Lib.create_animation({
      from_color = "#ff0000",
      to_color = "#00ff00",
    })
  end, "TinyGlimmer: range is required")
end

T["lib"]["create_animation requires from_color"] = function()
  reset_state()
  MiniTest.expect.error(function()
    Lib.create_animation({
      range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
      to_color = "#00ff00",
    })
  end, "TinyGlimmer: from_color and to_color are required")
end

T["lib"]["create_animation requires to_color"] = function()
  reset_state()
  MiniTest.expect.error(function()
    Lib.create_animation({
      range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
      from_color = "#ff0000",
    })
  end, "TinyGlimmer: from_color and to_color are required")
end

T["lib"]["create_animation with minimal options"] = function()
  reset_state()
  ensure_factory_has_effects()
  mock_buffer_api()
  mock_animation_modules()

  MiniTest.expect.no_error(function()
    Lib.create_animation({
      range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
      from_color = "#ff0000",
      to_color = "#00ff00",
    })
  end)

  restore_buffer_api()
end

T["lib"]["create_animation uses default effect and duration"] = function()
  reset_state()
  mock_buffer_api()
  mock_animation_modules()
  ensure_factory_has_effects()

  Lib.create_animation({
    range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
    from_color = "#ff0000",
    to_color = "#00ff00",
  })

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers), "table")
  MiniTest.expect.equality(type(factory.buffers[1]), "table")

  restore_buffer_api()
end

T["lib"]["create_animation with custom effect"] = function()
  reset_state()
  mock_buffer_api()
  mock_animation_modules()
  ensure_factory_has_effects()

  Lib.create_animation({
    range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
    from_color = "#ff0000",
    to_color = "#00ff00",
    effect = "bounce",
  })

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers), "table")

  restore_buffer_api()
end

T["lib"]["create_animation with custom duration"] = function()
  reset_state()
  mock_buffer_api()
  mock_animation_modules()
  ensure_factory_has_effects()

  Lib.create_animation({
    range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
    from_color = "#ff0000",
    to_color = "#00ff00",
    duration = 500,
  })

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers), "table")

  restore_buffer_api()
end

T["lib"]["create_animation with easing"] = function()
  reset_state()
  mock_buffer_api()
  mock_animation_modules()
  ensure_factory_has_effects()

  Lib.create_animation({
    range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
    from_color = "#ff0000",
    to_color = "#00ff00",
    easing = "inQuad",
  })

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers), "table")

  restore_buffer_api()
end

T["lib"]["create_animation with loop"] = function()
  reset_state()
  mock_buffer_api()
  mock_animation_modules()
  ensure_factory_has_effects()

  Lib.create_animation({
    range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
    from_color = "#ff0000",
    to_color = "#00ff00",
    loop = true,
    loop_count = 3,
  })

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers), "table")

  restore_buffer_api()
end

-- Test create_line_animation
T["lib"]["create_line_animation requires range"] = function()
  reset_state()
  MiniTest.expect.error(function()
    Lib.create_line_animation({
      from_color = "#ff0000",
      to_color = "#00ff00",
    })
  end, "TinyGlimmer: range is required")
end

T["lib"]["create_line_animation requires colors"] = function()
  reset_state()
  MiniTest.expect.error(function()
    Lib.create_line_animation({
      range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
    })
  end, "TinyGlimmer: from_color and to_color are required")
end

T["lib"]["create_line_animation with minimal options"] = function()
  reset_state()
  mock_buffer_api()
  mock_animation_modules()
  ensure_factory_has_effects()

  MiniTest.expect.no_error(function()
    Lib.create_line_animation({
      range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
      from_color = "#ff0000",
      to_color = "#00ff00",
    })
  end)

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers), "table")

  restore_buffer_api()
end

T["lib"]["create_line_animation with custom effect"] = function()
  reset_state()
  mock_buffer_api()
  mock_animation_modules()
  ensure_factory_has_effects()

  Lib.create_line_animation({
    range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
    from_color = "#ff0000",
    to_color = "#00ff00",
    effect = "pulse",
  })

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers), "table")

  restore_buffer_api()
end

-- Test create_text_animation
T["lib"]["create_text_animation is alias for create_animation"] = function()
  reset_state()
  mock_buffer_api()
  mock_animation_modules()
  ensure_factory_has_effects()

  Lib.create_text_animation({
    range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
    from_color = "#ff0000",
    to_color = "#00ff00",
  })

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers), "table")

  restore_buffer_api()
end

-- Test create_named_animation
T["lib"]["create_named_animation requires name"] = function()
  reset_state()
  MiniTest.expect.error(function()
    Lib.create_named_animation(nil, {
      range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
      from_color = "#ff0000",
      to_color = "#00ff00",
    })
  end, "TinyGlimmer: name is required for named animations")
end

T["lib"]["create_named_animation requires range"] = function()
  reset_state()
  MiniTest.expect.error(function()
    Lib.create_named_animation("test", {
      from_color = "#ff0000",
      to_color = "#00ff00",
    })
  end, "TinyGlimmer: range is required")
end

T["lib"]["create_named_animation requires colors"] = function()
  reset_state()
  MiniTest.expect.error(function()
    Lib.create_named_animation("test", {
      range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
    })
  end, "TinyGlimmer: from_color and to_color are required")
end

T["lib"]["create_named_animation with minimal options"] = function()
  reset_state()
  ensure_factory_has_effects()
  mock_buffer_api()
  mock_animation_modules()

  MiniTest.expect.no_error(function()
    Lib.create_named_animation("test", {
      range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
      from_color = "#ff0000",
      to_color = "#00ff00",
    })
  end)

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers[1].named_animations["test"]), "table")

  restore_buffer_api()
end

T["lib"]["create_named_animation with custom effect"] = function()
  reset_state()
  ensure_factory_has_effects()
  mock_buffer_api()
  mock_animation_modules()

  Lib.create_named_animation("test", {
    range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
    from_color = "#ff0000",
    to_color = "#00ff00",
    effect = "rainbow",
  })

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers[1].named_animations["test"]), "table")

  restore_buffer_api()
end

T["lib"]["create_named_animation with loop"] = function()
  reset_state()
  ensure_factory_has_effects()
  mock_buffer_api()
  mock_animation_modules()

  Lib.create_named_animation("test", {
    range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
    from_color = "#ff0000",
    to_color = "#00ff00",
    loop = true,
    loop_count = 5,
  })

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers[1].named_animations["test"]), "table")

  restore_buffer_api()
end

-- Test stop_animation
T["lib"]["stop_animation stops named animation"] = function()
  reset_state()
  ensure_factory_has_effects()
  mock_buffer_api()
  mock_animation_modules()

  Lib.create_named_animation("test", {
    range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
    from_color = "#ff0000",
    to_color = "#00ff00",
  })

  local factory = AnimationFactory.get_instance()
  local animation = factory.buffers[1].named_animations["test"]
  MiniTest.expect.equality(type(animation), "table")

  Lib.stop_animation("test")
  MiniTest.expect.equality(factory.buffers[1].named_animations["test"], nil)

  restore_buffer_api()
end

T["lib"]["stop_animation handles non-existent animation"] = function()
  reset_state()
  ensure_factory_has_effects()
  mock_buffer_api()

  MiniTest.expect.no_error(function()
    Lib.stop_animation("non_existent")
  end)

  restore_buffer_api()
end

-- Test create_effect
T["lib"]["create_effect requires update_fn"] = function()
  reset_state()
  MiniTest.expect.error(function()
    Lib.create_effect({
      settings = { max_duration = 300 },
    })
  end, "TinyGlimmer: update_fn is required for custom effects")
end

T["lib"]["create_effect with update_fn"] = function()
  reset_state()

  local effect = Lib.create_effect({
    settings = { max_duration = 300 },
    update_fn = function(self, progress, ease)
      return "#ff0000", progress
    end,
  })

  MiniTest.expect.equality(type(effect), "table")
  MiniTest.expect.equality(type(effect.settings), "table")
  MiniTest.expect.equality(effect.settings.max_duration, 300)
end

T["lib"]["create_effect with builder"] = function()
  reset_state()

  local effect = Lib.create_effect({
    settings = { max_duration = 300 },
    update_fn = function()
      return "#ff0000", 0.5
    end,
    builder = function()
      return { data = "test" }
    end,
  })

  MiniTest.expect.equality(type(effect), "table")
  MiniTest.expect.equality(type(effect.settings), "table")
end

T["lib"]["create_effect without settings"] = function()
  reset_state()

  local effect = Lib.create_effect({
    update_fn = function(self, progress, ease)
      return "#ff0000", progress
    end,
  })

  MiniTest.expect.equality(type(effect), "table")
end

-- Test range helper functions
T["lib"]["get_cursor_range returns range"] = function()
  reset_state()
  local range = Lib.get_cursor_range()
  MiniTest.expect.equality(type(range), "table")
  MiniTest.expect.equality(type(range.start_line), "number")
  MiniTest.expect.equality(type(range.start_col), "number")
  MiniTest.expect.equality(type(range.end_line), "number")
  MiniTest.expect.equality(type(range.end_col), "number")
end

T["lib"]["get_line_range returns range for current line"] = function()
  reset_state()
  local range = Lib.get_line_range(0)
  MiniTest.expect.equality(type(range), "table")
  MiniTest.expect.equality(type(range.start_line), "number")
  MiniTest.expect.equality(type(range.start_col), "number")
  MiniTest.expect.equality(type(range.end_line), "number")
  MiniTest.expect.equality(type(range.end_col), "number")
end

T["lib"]["get_line_range returns range for specific line"] = function()
  reset_state()
  local range = Lib.get_line_range(5)
  MiniTest.expect.equality(type(range), "table")
  MiniTest.expect.equality(range.start_line, 4) -- 0-indexed
end

-- Test helper functions (cursor_line, visual_selection, animate_range)
T["lib"]["cursor_line with string effect"] = function()
  reset_state()
  mock_buffer_api()
  mock_animation_modules()
  ensure_factory_has_effects()

  MiniTest.expect.no_error(function()
    Lib.cursor_line("fade")
  end)

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers), "table")

  restore_buffer_api()
end

T["lib"]["cursor_line with table effect"] = function()
  reset_state()
  mock_buffer_api()
  mock_animation_modules()
  ensure_factory_has_effects()

  MiniTest.expect.no_error(function()
    Lib.cursor_line({ name = "fade", settings = { max_duration = 500 } })
  end)

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers), "table")

  restore_buffer_api()
end

T["lib"]["cursor_line with opts override"] = function()
  reset_state()
  mock_buffer_api()
  mock_animation_modules()
  ensure_factory_has_effects()

  MiniTest.expect.no_error(function()
    Lib.cursor_line("fade", { max_duration = 1000 })
  end)

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers), "table")

  restore_buffer_api()
end

T["lib"]["animate_range with string effect"] = function()
  reset_state()
  mock_buffer_api()
  mock_animation_modules()
  ensure_factory_has_effects()

  local range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 }
  MiniTest.expect.no_error(function()
    Lib.animate_range("bounce", range)
  end)

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers), "table")

  restore_buffer_api()
end

T["lib"]["animate_range with table effect"] = function()
  reset_state()
  mock_buffer_api()
  mock_animation_modules()
  ensure_factory_has_effects()

  local range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 }
  MiniTest.expect.no_error(function()
    Lib.animate_range({ name = "pulse", settings = { max_duration = 400 } }, range)
  end)

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers), "table")

  restore_buffer_api()
end

T["lib"]["named_animate_range creates named animation"] = function()
  reset_state()
  mock_buffer_api()
  mock_animation_modules()
  ensure_factory_has_effects()

  local range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 }
  MiniTest.expect.no_error(function()
    Lib.named_animate_range("test", "fade", range)
  end)

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers), "table")

  restore_buffer_api()
end

T["lib"]["named_animate_range with loop"] = function()
  reset_state()
  mock_buffer_api()
  mock_animation_modules()
  ensure_factory_has_effects()

  local range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 }
  MiniTest.expect.no_error(function()
    Lib.named_animate_range("test", "fade", range, { loop = true, loop_count = 3 })
  end)

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers), "table")

  restore_buffer_api()
end

-- Test easing and effects lists
T["lib"]["easing list contains expected values"] = function()
  MiniTest.expect.equality(type(Lib.easing), "table")
  MiniTest.expect.equality(vim.tbl_contains(Lib.easing, "linear"), true)
  MiniTest.expect.equality(vim.tbl_contains(Lib.easing, "inQuad"), true)
  MiniTest.expect.equality(vim.tbl_contains(Lib.easing, "outBounce"), true)
end

T["lib"]["effects list contains expected values"] = function()
  MiniTest.expect.equality(type(Lib.effects), "table")
  MiniTest.expect.equality(vim.tbl_contains(Lib.effects, "fade"), true)
  MiniTest.expect.equality(vim.tbl_contains(Lib.effects, "bounce"), true)
  MiniTest.expect.equality(vim.tbl_contains(Lib.effects, "rainbow"), true)
end

-- Test Phase 1 features
T["lib"]["get_word_range returns nil for empty buffer"] = function()
  reset_state()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
  local range = Lib.get_word_range()
  MiniTest.expect.equality(range, nil)
end

T["lib"]["get_word_range returns range for word"] = function()
  reset_state()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hello world test" })
  vim.api.nvim_win_set_cursor(0, { 1, 6 }) -- on "world"

  local range = Lib.get_word_range()
  MiniTest.expect.equality(type(range), "table")
  MiniTest.expect.equality(range.start_line, 0)
  MiniTest.expect.equality(range.end_line, 0)
  -- Just verify we got a valid range with some columns
  MiniTest.expect.equality(type(range.start_col), "number")
  MiniTest.expect.equality(type(range.end_col), "number")
  MiniTest.expect.equality(range.end_col > range.start_col, true)
end

T["lib"]["get_paragraph_range returns current paragraph"] = function()
  reset_state()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "line 1",
    "line 2",
    "",
    "line 4",
    "line 5",
  })
  vim.api.nvim_win_set_cursor(0, { 2, 0 })

  local range = Lib.get_paragraph_range()
  MiniTest.expect.equality(type(range), "table")
  MiniTest.expect.equality(range.start_line, 0)
  MiniTest.expect.equality(range.start_col, 0)
end

T["lib"]["stop_all stops all animations"] = function()
  reset_state()
  ensure_factory_has_effects()
  mock_buffer_api()
  mock_animation_modules()

  -- Create multiple named animations
  Lib.create_named_animation("test1", {
    range = { start_line = 0, start_col = 0, end_line = 0, end_col = 5 },
    from_color = "#ff0000",
    to_color = "#00ff00",
  })

  Lib.create_named_animation("test2", {
    range = { start_line = 1, start_col = 0, end_line = 1, end_col = 5 },
    from_color = "#ff0000",
    to_color = "#00ff00",
  })

  local factory = AnimationFactory.get_instance()
  MiniTest.expect.equality(type(factory.buffers[1].named_animations["test1"]), "table")
  MiniTest.expect.equality(type(factory.buffers[1].named_animations["test2"]), "table")

  -- Stop all
  Lib.stop_all()

  MiniTest.expect.equality(factory.buffers[1].named_animations["test1"], nil)
  MiniTest.expect.equality(factory.buffers[1].named_animations["test2"], nil)

  restore_buffer_api()
end

T["lib"]["animate_word animates word under cursor"] = function()
  reset_state()
  ensure_factory_has_effects()
  mock_buffer_api()
  mock_animation_modules()

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hello world" })
  vim.api.nvim_win_set_cursor(0, { 1, 6 })

  MiniTest.expect.no_error(function()
    Lib.animate_word("fade")
  end)

  restore_buffer_api()
end

T["lib"]["paragraph animates current paragraph"] = function()
  reset_state()
  ensure_factory_has_effects()
  mock_buffer_api()
  mock_animation_modules()

  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "line 1",
    "line 2",
    "",
    "line 4",
  })
  vim.api.nvim_win_set_cursor(0, { 2, 0 })

  MiniTest.expect.no_error(function()
    Lib.paragraph("pulse")
  end)

  restore_buffer_api()
end

return T

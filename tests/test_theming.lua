local T = MiniTest.new_set()

local function setup_plugin(opts)
  require("tiny-glimmer").setup(opts)
end

T["apply()"] = MiniTest.new_set()

T["apply()"]["can be called"] = function()
  setup_plugin({})

  local glimmer = require("tiny-glimmer")

  local ok = pcall(function()
    glimmer.apply()
  end)

  MiniTest.expect.equality(ok, true)
end

T["autoreload"] = MiniTest.new_set()

T["autoreload"]["creates autocmd when enabled"] = function()
  setup_plugin({
    autoreload = true,
  })

  local autocmds = vim.api.nvim_get_autocmds({
    event = "ColorScheme",
    group = require("tiny-glimmer.namespace").tiny_glimmer_animation_group,
  })

  MiniTest.expect.equality(#autocmds > 0, true)
end

T["autoreload"]["default is false"] = function()
  local defaults = require("tiny-glimmer.config.defaults")
  MiniTest.expect.equality(defaults.autoreload, false)
end

T["apply()"]["re-evaluates highlight groups"] = function()
  -- Set up a custom highlight group
  vim.api.nvim_set_hl(0, "TestHighlight", { bg = "#ff0000" })
  
  setup_plugin({
    animations = {
      test = {
        from_color = "TestHighlight",
        to_color = "#00ff00",
      }
    }
  })
  
  local glimmer = require("tiny-glimmer")
  local first_color = glimmer.config.animations.test.from_color
  
  -- Change the highlight group color
  vim.api.nvim_set_hl(0, "TestHighlight", { bg = "#0000ff" })
  
  -- Apply should re-evaluate the highlight group
  glimmer.apply()
  
  local second_color = glimmer.config.animations.test.from_color
  
  MiniTest.expect.equality(first_color:lower(), "#ff0000")
  MiniTest.expect.equality(second_color:lower(), "#0000ff")
end

return T

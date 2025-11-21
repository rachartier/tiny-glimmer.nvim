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

return T

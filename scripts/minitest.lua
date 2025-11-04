-- Project-specific test runner for tiny-glimmer.nvim
-- This script is used by mini.test to run tests

local function setup_test_env()
  -- Add lua directory to package.path for requiring modules
  local project_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
  package.path =
    string.format("%s/lua/?.lua;%s/lua/?/init.lua;%s", project_root, project_root, package.path)
end

-- Setup environment before running tests
setup_test_env()

-- Load test configuration
require("tests.init")

-- Override reporter for headless mode (always use stdout in scripts)
MiniTest.setup({
  execute = {
    reporter = MiniTest.gen_reporter.stdout(),
  },
})

-- Run tests
MiniTest.run()

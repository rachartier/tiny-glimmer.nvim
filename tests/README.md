# Tests for tiny-glimmer.nvim

This directory contains unit tests for tiny-glimmer.nvim using [mini.test](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-test.md).

## Prerequisites

Install mini.nvim to run tests:

```lua
-- Using lazy.nvim
{ 'echasnovski/mini.nvim', version = '*' }

-- Or standalone
{ 'echasnovski/mini.test', version = '*' }
```

## Running Tests

### Run all tests

```bash
make test
```

Or directly:

```bash
./scripts/test.sh
```

### Run a specific test file

```bash
make test-file FILE=tests/test_init.lua
```

### Run tests interactively

```bash
make test-interactive
```

### From Neovim

```vim
:lua MiniTest.run()
:lua MiniTest.run_file('tests/test_init.lua')
:lua MiniTest.run_at_location()
```

## Test Structure

```
tests/
├── init.lua                   # MiniTest setup and keymaps
├── helpers.lua                # Helper functions for testing
├── test_init.lua              # Tests for init.lua
├── test_api.lua               # Tests for api.lua
├── test_setup.lua             # Tests for setup.lua
├── test_config_defaults.lua   # Tests for config/defaults.lua
└── test_config_highlights.lua # Tests for config/highlights.lua
```

## Test Coverage

### test_init.lua
- Module structure and exports
- setup() function behavior
- API method loading
- custom_remap() functionality
- hijack_done state

### test_api.lua
- enable/disable/toggle functionality
- change_hl() for single, multiple, and all animations
- get_background_hl()
- Search method warnings
- Paste method warnings
- Undo/redo method warnings

### test_setup.lua
- initialize() function
- Config merging with defaults
- Deep merging of nested options
- Highlight sanitization
- Overwrite and preset configuration

### test_config_defaults.lua
- Default configuration structure
- Required fields presence
- Animation definitions
- Preset and support configurations

### test_config_highlights.lua
- process_highlight_color() function
- Hex color handling
- Highlight group conversion
- Transparency handling
- sanitize_highlights() behavior

## Helpers

The `tests/helpers.lua` file provides utility functions for testing:

- `H.make_buf(lines)` - Create a buffer with given lines
- `H.with_buf(lines, fn)` - Execute function with temporary buffer
- `H.setup_win(buf, cursor, width)` - Setup window with buffer and cursor
- `H.with_win_buf(lines, cursor, width, fn)` - Execute function with temporary buffer and window
- `H.make_config(overrides)` - Create mock config with overrides
- `H.setup_glimmer(config)` - Setup mock glimmer module for testing
- `H.make_animation(overrides)` - Create mock animation settings

## Writing New Tests

Tests follow the mini.test structure:

```lua
local T = MiniTest.new_set()

T['group name'] = MiniTest.new_set()

T['group name']['test description'] = function()
  -- Test code
  MiniTest.expect.equality(actual, expected)
end

return T
```

### Available Expectations

- `MiniTest.expect.equality(a, b, message)` - Assert a == b
- `MiniTest.expect.no.equality(a, b, message)` - Assert a ~= b
- `MiniTest.expect.truthy(value, message)` - Assert value is truthy
- `MiniTest.expect.no.truthy(value, message)` - Assert value is falsy
- `MiniTest.expect.error(func, message)` - Assert function throws error
- `MiniTest.expect.no.error(func, message)` - Assert function doesn't throw

See [mini.test documentation](https://github.com/echasnovski/mini.nvim/blob/main/doc/mini-test.txt) for more.

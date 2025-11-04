#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Check if mini.test is available
if ! nvim --headless --noplugin -u NONE -c "lua local ok = pcall(require, 'mini.test'); os.exit(ok and 0 or 1)" 2>/dev/null; then
    echo "Error: mini.test is not installed"
    echo ""
    echo "Please install mini.nvim to run tests:"
    echo "  https://github.com/echasnovski/mini.nvim"
    echo ""
    echo "Using lazy.nvim:"
    echo "  { 'echasnovski/mini.nvim', version = '*' }"
    echo ""
    echo "Or standalone:"
    echo "  { 'echasnovski/mini.test', version = '*' }"
    exit 1
fi

if [ "$1" = "file" ] && [ -n "$2" ]; then
  nvim --headless --noplugin -u NONE \
    -c "lua package.path = package.path .. ';lua/?.lua;lua/?/init.lua'" \
    -c "lua MiniTest = require('mini.test'); MiniTest.setup({ execute = { reporter = MiniTest.gen_reporter.stdout() } })" \
    -c "lua MiniTest.run_file('$2')" \
    -c "qa!"
elif [ "$1" = "interactive" ]; then
  nvim -u NONE \
    -c "lua package.path = package.path .. ';lua/?.lua;lua/?/init.lua'" \
    -c "lua require('tests.init')"
else
  nvim --headless --noplugin -u NONE \
    -c "lua package.path = package.path .. ';lua/?.lua;lua/?/init.lua'" \
    -c "lua require('tests.init'); MiniTest.setup({ execute = { reporter = MiniTest.gen_reporter.stdout() } }); MiniTest.run()" \
    -c "qa!"
fi

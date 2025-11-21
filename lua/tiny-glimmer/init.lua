local M = {}

M.config = nil
M.hijack_done = false

function M.setup(user_options)
  local setup_module = require("tiny-glimmer.setup")
  M.config = setup_module.initialize(user_options)

  local api = require("tiny-glimmer.api")
  M.enable = api.enable
  M.disable = api.disable
  M.toggle = api.toggle
  M.change_hl = api.change_hl
  M.get_background_hl = api.get_background_hl
  M.search_next = api.search_next
  M.search_prev = api.search_prev
  M.search_under_cursor = api.search_under_cursor
  M.paste = api.paste
  M.Paste = api.Paste
  M.undo = api.undo
  M.redo = api.redo
  M.apply = api.apply
end

--- Custom remap delegation (needed by external callers)
function M.custom_remap(map, mode, callback)
  local lhs = map
  local rhs = nil

  if type(map) == "table" then
    lhs = map.lhs
    rhs = map.rhs
  else
    if map:lower() == "<c-r>" then
      lhs = "<c-r>"
    else
      lhs = map:sub(1, 1)
    end
  end

  require("tiny-glimmer.hijack").hijack(mode, lhs, rhs, callback)
end

return M

local M = {}

M.config = nil
M.user_config = nil
M.hijack_done = false

function M.setup(user_options)
  local setup_module = require("tiny-glimmer.setup")
  M.user_config = user_options
  M.config = setup_module.initialize(user_options)

  for name, fn in pairs(require("tiny-glimmer.api")) do
    M[name] = fn
  end
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

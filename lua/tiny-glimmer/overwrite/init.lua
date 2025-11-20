local M = {}

setmetatable(M, {
  __index = function(_, key)
    return require("tiny-glimmer.overwrite." .. key)
  end,
})

return M

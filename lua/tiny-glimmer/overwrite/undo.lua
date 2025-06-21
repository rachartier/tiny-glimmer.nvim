local M = {}

local handle_text_change_animation =
  require("tiny-glimmer.animation.text_change").handle_text_change_animation

local function create_callback(opts)
  return function(ranges)
    for i = 1, #ranges do
      local range = ranges[i]

      if ranges[i] ~= nil then
        require("tiny-glimmer.animation.factory")
          .get_instance()
          :create_named_text_animation("undo_" .. i, opts.default_animation, {
            base = { range = range },
          })
      end
    end
  end
end

---Animate undo operation
---@param opts table Animation options
function M.undo(opts)
  handle_text_change_animation(create_callback(opts))
end

---Animate redo operation
---@param opts table Animation options
function M.redo(opts)
  handle_text_change_animation(create_callback(opts))
end

return M

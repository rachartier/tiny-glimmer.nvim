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
          :create_named_text_animation("paste_" .. i, opts.default_animation, {
            base = { range = range },
          })
      end
    end
  end
end

local function animate_paste(opts)
  handle_text_change_animation(create_callback(opts))
end

M.paste = animate_paste
M.Paste = animate_paste

return M

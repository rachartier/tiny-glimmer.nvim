local txt = [[
Fade				################# azertyuiop123456

Reverse Fade		################# azertyuiop123456

Bounce				################# azertyuiop123456

Left To Right     	################# azertyuiop123456

Pulse               ################# azertyuiop123456

Rainbow             ################# azertyuiop123456

Fade
Bounce
Left To Right
Pulse
Rainbow


AA
AA
AA
AA
AA
BB
AA
AA
AA
BB
BB
AA
BB
BB
BB

123456789
123456789
12345678
1234567
123456
12345
1234
123
12
1
12
123
1234
12345
123456
1234567
12345678
123456789

###################################
###################################
###################################
##########             ############
##########             ############
##########             ############
##########             ############
##########             ############
##########             ############
##########             ############
###################################
###################################
###################################

Reverse Fade		################# azertyuiop123456

Bounce				################# azertyuiop123456

Left To Right     	################# azertyuiop123456

Pulse               ################# azertyuiop123456

Rainbow             ################# azertyuiop123456

Fade
Bounce
Left To Right
Pulse
Rainbow


AA
AA
AA
AA
AA
BB
AA
AA
AA
BB
BB
AA
BB
BB
BB

123456789
123456789
12345678
1234567
123456
12345
1234
123
12
1
12
123
1234
12345
123456
1234567
12345678
123456789

###################################
###################################
###################################
##########             ############
##########             ############
##########             ############
##########             ############
##########             ############
##########             ############
##########             ############
###################################
###################################
###################################
]]

local AnimationFactory = require("tiny-glimmer.animation.factory")

function test()
  local buf_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  for i, line in ipairs(buf_content) do
    if #line > 0 then
      local range = {
        start_line = i - 1,
        start_col = 0,
        end_line = i - 1,
        end_col = #line,
      }

      local animation_type = "none"

      if line:lower():find("reverse fade") then
        animation_type = "reverse_fade"
      elseif line:lower():find("fade") then
        animation_type = "fade"
      elseif line:lower():find("bounce") then
        animation_type = "bounce"
      elseif line:lower():find("left_to_right") then
        animation_type = "left_to_right"
      elseif line:lower():find("pulse") then
        animation_type = "pulse"
      elseif line:lower():find("rainbow") then
        animation_type = "rainbow"
      end

      if animation_type ~= "none" then
        AnimationFactory.get_instance():create_text_animation("left_to_right", {
          base = {
            range = range,
          },
        })
      end
    end
  end
end

-- AnimationFactory.get_instance():create_rectangle_animation("rainbow", {
-- base =          {
-- 		range = {
-- 			start_line = 180,
-- 			start_col = 10,
-- 			end_line = 185,
-- 			end_col = 40,
-- 		},
-- 	},
-- })

local i = require("tiny-glimmer.namespace_id_pool")

vim.print(i.get_pool_stats())

test()

-- vim.api.nvim_set_hl(0, "CursorLine", { bg = "#000000" })

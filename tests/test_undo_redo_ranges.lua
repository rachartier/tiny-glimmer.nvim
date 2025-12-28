local MiniTest = require("mini.test")
local undo = require("tiny-glimmer.overwrite.undo")

local T = MiniTest.new_set()

local add_guards = undo._test.add_guards
local remove_guards = undo._test.remove_guards
local insert_range = undo._test.insert_range

local function undo_redo_test(inputs, output)
  return function()
    local ranges = add_guards {}
    for input in vim.iter(inputs) do
      insert_range(ranges, input.old_range, input.new_range)
    end
    ranges = remove_guards(ranges)
    MiniTest.expect.equality(ranges, output)
  end
end

T["insert_range"] = MiniTest.new_set()

--[[
Buffer contents:
aaa bbb ccc
Command (cursor on the first `b`):
ciwdd + u (+ r)
]]
T["insert_range"]["basic inline (undo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 0, start_col = 4, end_line = 0, end_col = 7 },
      old_range = { start_line = 0, start_col = 4, end_line = 0, end_col = 7 },
    }
  },
  {
    { start_line = 0, start_col = 4, end_line = 0, end_col = 7 },
  }
)
T["insert_range"]["basic inline (redo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 0, start_col = 4, end_line = 0, end_col = 6 },
      old_range = { start_line = 0, start_col = 4, end_line = 0, end_col = 6 },
    }
  },
  {
    { start_line = 0, start_col = 4, end_line = 0, end_col = 6 },
  }
)

--[[
Buffer contents:
aaa bbb ccc
Command (cursor on the first `b`):
ciw\n\nddd + u (+ r)
]]
T["insert_range"]["basic multiline (undo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 0 },
      old_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 0 },
    },
    {
      new_range = { start_line = 1, start_col = 0, end_line = 1, end_col = 0 },
      old_range = { start_line = 1, start_col = 0, end_line = 1, end_col = 0 },
    },
    {
      new_range = { start_line = 0, start_col = 4, end_line = 0, end_col = 5 },
      old_range = { start_line = 0, start_col = 4, end_line = 0, end_col = 8 },
    },
    {
      new_range = { start_line = 0, start_col = 4, end_line = 0, end_col = 7 },
      old_range = { start_line = 0, start_col = 4, end_line = 0, end_col = 4 },
    },
  },
  {
    { start_line = 0, start_col = 4, end_line = 0, end_col = 8 },
  }
)
T["insert_range"]["basic multiline (redo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 0, start_col = 4, end_line = 0, end_col = 4 },
      old_range = { start_line = 0, start_col = 4, end_line = 0, end_col = 4 },
    },
    {
      new_range = { start_line = 0, start_col = 4, end_line = 1, end_col = 0 },
      old_range = { start_line = 0, start_col = 4, end_line = 2, end_col = 3 },
    },
    {
      new_range = { start_line = 1, start_col = 0, end_line = 2, end_col = 0 },
      old_range = { start_line = 1, start_col = 0, end_line = 1, end_col = 0 },
    },
    {
      new_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 3 },
      old_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 0 },
    },
  },
  {
    { start_line = 0, start_col = 4, end_line = 2, end_col = 3 },
  }
)

--[[
https://github.com/rachartier/tiny-glimmer.nvim/issues/45#issuecomment-3567100390

Buffer contents:
aaa
bbb
Command (cursor on the second line):
occc<Esc> + u (+ r)
]]
T["insert_range"]["line open EOF (undo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 0 },
      old_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 3 },
    },
    {
      new_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 0 },
      old_range = { start_line = 2, start_col = 0, end_line = 3, end_col = 0 },
    },
  },
  {}
)
T["insert_range"]["line open EOF (redo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 2, start_col = 0, end_line = 3, end_col = 0 },
      old_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 0 },
    },
    {
      new_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 3 },
      old_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 0 },
    },
  },
  {
    { start_line = 2, start_col = 0, end_line = 3, end_col = 0 },
  }
)

--[[
https://github.com/rachartier/tiny-glimmer.nvim/issues/45#issue-3655067656

Buffer contents:
    aaa
    ccc
Command (cursor on the first `a`):
obbb<Esc> + u (+ r)
]]
T["insert_range"]["line open with indentation (undo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 1, start_col = 4, end_line = 1, end_col = 4 },
      old_range = { start_line = 1, start_col = 4, end_line = 1, end_col = 7 },
    },
    {
      new_range = { start_line = 1, start_col = 0, end_line = 1, end_col = 0 },
      old_range = { start_line = 1, start_col = 0, end_line = 2, end_col = 0 },
    },
  },
  {}
)
T["insert_range"]["line open with indentation (redo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 1, start_col = 0, end_line = 2, end_col = 0 },
      old_range = { start_line = 1, start_col = 0, end_line = 1, end_col = 0 },
    },
    {
      new_range = { start_line = 1, start_col = 4, end_line = 1, end_col = 7 },
      old_range = { start_line = 1, start_col = 4, end_line = 1, end_col = 4 },
    },
  },
  {
    { start_line = 1, start_col = 0, end_line = 2, end_col = 0 },
  }
)

--[[
https://github.com/rachartier/tiny-glimmer.nvim/issues/45#issue-3655067656

Buffer contents:
    aaa
    bbb
Command (cursor on the first `a`):
o<Esc> + u (+ r)
]]
T["insert_range"]["empty line open with indentation (undo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 1, start_col = 0, end_line = 1, end_col = 4 },
      old_range = { start_line = 1, start_col = 0, end_line = 1, end_col = 0 },
    },
    {
      new_range = { start_line = 1, start_col = 0, end_line = 1, end_col = 0 },
      old_range = { start_line = 1, start_col = 0, end_line = 2, end_col = 0 },
    },
  },
  {}
)
T["insert_range"]["empty line open with indentation (redo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 1, start_col = 0, end_line = 2, end_col = 0 },
      old_range = { start_line = 1, start_col = 0, end_line = 1, end_col = 0 },
    },
    {
      new_range = { start_line = 1, start_col = 0, end_line = 1, end_col = 0 },
      old_range = { start_line = 1, start_col = 0, end_line = 1, end_col = 4 },
    },
  },
  {
    { start_line = 1, start_col = 0, end_line = 2, end_col = 0 },
  }
)

--[[
Buffer contents:
aaa
ccc
Command (cursor on the last `a`):
abbb<CR>bbb<CR><CR><Esc> + u (+ r)
]]
T["insert_range"]["insertion over line (undo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 0 },
      old_range = { start_line = 2, start_col = 0, end_line = 3, end_col = 0 },
    },
    {
      new_range = { start_line = 1, start_col = 3, end_line = 1, end_col = 3 },
      old_range = { start_line = 1, start_col = 3, end_line = 2, end_col = 0 },
    },
    {
      new_range = { start_line = 1, start_col = 0, end_line = 1, end_col = 0 },
      old_range = { start_line = 1, start_col = 0, end_line = 1, end_col = 3 },
    },
    {
      new_range = { start_line = 0, start_col = 6, end_line = 0, end_col = 6 },
      old_range = { start_line = 0, start_col = 6, end_line = 1, end_col = 0 },
    },
    {
      new_range = { start_line = 0, start_col = 3, end_line = 0, end_col = 3 },
      old_range = { start_line = 0, start_col = 3, end_line = 0, end_col = 6 },
    },
  },
  {}
)
T["insert_range"]["insertion over line (redo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 0, start_col = 3, end_line = 0, end_col = 6 },
      old_range = { start_line = 0, start_col = 3, end_line = 0, end_col = 3 },
    },
    {
      new_range = { start_line = 0, start_col = 6, end_line = 1, end_col = 0 },
      old_range = { start_line = 0, start_col = 6, end_line = 0, end_col = 6 },
    },
    {
      new_range = { start_line = 1, start_col = 0, end_line = 1, end_col = 3 },
      old_range = { start_line = 1, start_col = 0, end_line = 1, end_col = 0 },
    },
    {
      new_range = { start_line = 1, start_col = 3, end_line = 2, end_col = 0 },
      old_range = { start_line = 1, start_col = 3, end_line = 1, end_col = 3 },
    },
    {
      new_range = { start_line = 2, start_col = 0, end_line = 3, end_col = 0 },
      old_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 0 },
    },
  },
  {
    { start_line = 0, start_col = 3, end_line = 3, end_col = 0 },
  }
)

--[[
Buffer contents:
aaa
bbb
Command (cursor on the first `b`):
i<BS><BS><BS><Esc> + u (+ r)
]]
T["insert_range"]["deletion over line (undo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 0, start_col = 1, end_line = 0, end_col = 3 },
      old_range = { start_line = 0, start_col = 1, end_line = 0, end_col = 1 },
    },
    {
      new_range = { start_line = 0, start_col = 3, end_line = 1, end_col = 0 },
      old_range = { start_line = 0, start_col = 3, end_line = 0, end_col = 3 },
    },
  },
  {
    { start_line = 0, start_col = 1, end_line = 1, end_col = 0 },
  }
)
T["insert_range"]["deletion over line (redo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 0, start_col = 3, end_line = 0, end_col = 3 },
      old_range = { start_line = 0, start_col = 3, end_line = 1, end_col = 0 },
    },
    {
      new_range = { start_line = 0, start_col = 1, end_line = 0, end_col = 1 },
      old_range = { start_line = 0, start_col = 1, end_line = 0, end_col = 3 },
    },
  },
  {}
)

--[[
Buffer contents:
**aaa**
Command:
:%s/*/@/g + u (+ r)
]]
T["insert_range"]["multiple locations (undo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 0, start_col = 6, end_line = 0, end_col = 7 },
      old_range = { start_line = 0, start_col = 6, end_line = 0, end_col = 7 },
    },
    {
      new_range = { start_line = 0, start_col = 5, end_line = 0, end_col = 6 },
      old_range = { start_line = 0, start_col = 5, end_line = 0, end_col = 6 },
    },
    {
      new_range = { start_line = 0, start_col = 1, end_line = 0, end_col = 2 },
      old_range = { start_line = 0, start_col = 1, end_line = 0, end_col = 2 },
    },
    {
      new_range = { start_line = 0, start_col = 0, end_line = 0, end_col = 1 },
      old_range = { start_line = 0, start_col = 0, end_line = 0, end_col = 1 },
    },
  },
  {
    { start_line = 0, start_col = 0, end_line = 0, end_col = 2 },
    { start_line = 0, start_col = 5, end_line = 0, end_col = 7 },
  }
)
T["insert_range"]["multiple locations (redo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 0, start_col = 0, end_line = 0, end_col = 1 },
      old_range = { start_line = 0, start_col = 0, end_line = 0, end_col = 1 },
    },
    {
      new_range = { start_line = 0, start_col = 1, end_line = 0, end_col = 2 },
      old_range = { start_line = 0, start_col = 1, end_line = 0, end_col = 2 },
    },
    {
      new_range = { start_line = 0, start_col = 5, end_line = 0, end_col = 6 },
      old_range = { start_line = 0, start_col = 5, end_line = 0, end_col = 6 },
    },
    {
      new_range = { start_line = 0, start_col = 6, end_line = 0, end_col = 7 },
      old_range = { start_line = 0, start_col = 6, end_line = 0, end_col = 7 },
    },
  },
  {
    { start_line = 0, start_col = 0, end_line = 0, end_col = 2 },
    { start_line = 0, start_col = 5, end_line = 0, end_col = 7 },
  }
)

--[[
Buffer contents:
aaa bbb
bbb bbb
Command:
:%s/bbb/dd\r/g + u (+ r)
]]
T["insert_range"]["multiple locations multiline insert (undo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 3, start_col = 1, end_line = 3, end_col = 4 },
      old_range = { start_line = 3, start_col = 1, end_line = 4, end_col = 0 },
    },
    {
      new_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 3 },
      old_range = { start_line = 2, start_col = 0, end_line = 3, end_col = 0 },
    },
    {
      new_range = { start_line = 0, start_col = 4, end_line = 0, end_col = 7 },
      old_range = { start_line = 0, start_col = 4, end_line = 1, end_col = 0 },
    },
  },
  {
    { start_line = 0, start_col = 4, end_line = 0, end_col = 7 },
    { start_line = 1, start_col = 0, end_line = 1, end_col = 3 },
    { start_line = 1, start_col = 4, end_line = 1, end_col = 7 },
  }
)
T["insert_range"]["multiple locations multiline insert (redo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 0, start_col = 4, end_line = 1, end_col = 0 },
      old_range = { start_line = 0, start_col = 4, end_line = 0, end_col = 7 },
    },
    {
      new_range = { start_line = 2, start_col = 0, end_line = 3, end_col = 0 },
      old_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 3 },
    },
    {
      new_range = { start_line = 3, start_col = 1, end_line = 4, end_col = 0 },
      old_range = { start_line = 3, start_col = 1, end_line = 3, end_col = 4 },
    },
  },
  {
    { start_line = 0, start_col = 4, end_line = 1, end_col = 0 },
    { start_line = 2, start_col = 0, end_line = 3, end_col = 0 },
    { start_line = 3, start_col = 1, end_line = 4, end_col = 0 },
  }
)

--[[
Buffer contents:
abc
abc
abc
Command:
%s/c\na//g + u (+ r)
]]
T["insert_range"]["multiple locations multiline remove (undo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 0, start_col = 3, end_line = 1, end_col = 1 },
      old_range = { start_line = 0, start_col = 3, end_line = 0, end_col = 3 },
    },
    {
      new_range = { start_line = 0, start_col = 2, end_line = 1, end_col = 1 },
      old_range = { start_line = 0, start_col = 2, end_line = 0, end_col = 2 },
    },
  },
  {
    { start_line = 0, start_col = 2, end_line = 1, end_col = 1 },
    { start_line = 1, start_col = 2, end_line = 2, end_col = 1 },
  }
)
T["insert_range"]["multiple locations multiline remove (redo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 0, start_col = 2, end_line = 0, end_col = 2 },
      old_range = { start_line = 0, start_col = 2, end_line = 1, end_col = 1 },
    },
    {
      new_range = { start_line = 0, start_col = 3, end_line = 0, end_col = 3 },
      old_range = { start_line = 0, start_col = 3, end_line = 1, end_col = 1 },
    },
  },
  {}
)

--[[
Buffer contents:
ab
ba
Command:
%s/b/d\rc/g + u (+ r)
]]
T["insert_range"]["multiple locations multiline replace (undo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 1 },
      old_range = { start_line = 2, start_col = 0, end_line = 3, end_col = 1 },
    },
    {
      new_range = { start_line = 0, start_col = 1, end_line = 0, end_col = 2 },
      old_range = { start_line = 0, start_col = 1, end_line = 1, end_col = 1 },
    },
  },
  {
    { start_line = 0, start_col = 1, end_line = 0, end_col = 2 },
    { start_line = 1, start_col = 0, end_line = 1, end_col = 1 },
  }
)
T["insert_range"]["multiple locations multiline replace (redo)"] = undo_redo_test(
  {
    {
      new_range = { start_line = 0, start_col = 1, end_line = 1, end_col = 1 },
      old_range = { start_line = 0, start_col = 1, end_line = 0, end_col = 2 },
    },
    {
      new_range = { start_line = 2, start_col = 0, end_line = 3, end_col = 1 },
      old_range = { start_line = 2, start_col = 0, end_line = 2, end_col = 1 },
    },
  },
  {
    { start_line = 0, start_col = 1, end_line = 1, end_col = 1 },
    { start_line = 2, start_col = 0, end_line = 3, end_col = 1 },
  }
)

return T

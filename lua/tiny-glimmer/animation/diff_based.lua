local M = {}

---Find longest common substring position in both strings
---@param before string
---@param after string
---@return number, number Start position in 'before' and 'after' (0-indexed), and length
local function find_longest_common_substring(before, after)
  local max_len = 0
  local before_start = 0
  local after_start = 0
  
  for i = 1, #before do
    for j = 1, #after do
      local len = 0
      while i + len <= #before and j + len <= #after and 
            before:sub(i + len, i + len) == after:sub(j + len, j + len) do
        len = len + 1
      end
      if len > max_len then
        max_len = len
        before_start = i - 1  -- Convert to 0-indexed
        after_start = j - 1
      end
    end
  end
  
  return before_start, after_start, max_len
end

---Simple character-level diff that finds changed regions
---Works by finding longest common substring and marking everything else as changed
---@param before string
---@param after string  
---@return table[] List of {start_col, end_col} ranges in 'after' string
local function find_changed_ranges(before, after)
  if before == after then
    return {}
  end
  
  if #before == 0 then
    return {{start_col = 0, end_col = #after}}
  end
  
  if #after == 0 then
    return {}
  end
  
  local ranges = {}
  
  -- Find longest common substring
  local _, after_match_start, match_len = find_longest_common_substring(before, after)
  
  if match_len == 0 then
    -- No common substring, entire 'after' is changed
    return {{start_col = 0, end_col = #after}}
  end
  
  local after_match_end = after_match_start + match_len
  
  -- Region before the match
  if after_match_start > 0 then
    table.insert(ranges, {
      start_col = 0,
      end_col = after_match_start,
    })
  end
  
  -- Region after the match
  if after_match_end < #after then
    table.insert(ranges, {
      start_col = after_match_end,
      end_col = #after,
    })
  end
  
  return ranges
end

---Compares buffer state and triggers animation callback with changed ranges
---@param bufnr number Buffer number
---@param before_lines table Lines before change
---@param before_tick number Changedtick before change
---@param callback function Function to call with changed ranges
function M.compare_and_animate(bufnr, before_lines, before_tick, callback)
  local after_tick = vim.api.nvim_buf_get_changedtick(bufnr)
  
  -- No changes
  if after_tick == before_tick then
    return
  end

  local after_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  
  -- Use vim.diff to calculate changes at line level
  local diff_result = vim.diff(
    table.concat(before_lines, "\n"),
    table.concat(after_lines, "\n"),
    {
      result_type = "indices",
      algorithm = "histogram",
    }
  )

  if not diff_result or #diff_result == 0 then
    return
  end

  local ranges = {}
  
  for _, diff in ipairs(diff_result) do
    -- diff format: {start_a, count_a, start_b, count_b}
    -- start_a, count_a: lines in 'before' (1-indexed)
    -- start_b, count_b: lines in 'after' (1-indexed)
    local start_line_before = diff[1] - 1 -- Convert to 0-indexed
    local count_before = diff[2]
    local start_line_after = diff[3] - 1 -- Convert to 0-indexed
    local count_after = diff[4]

    if count_after > 0 then
      -- For each changed line, find character-level differences
      for i = 0, count_after - 1 do
        local line_idx_after = start_line_after + i
        local line_idx_before = start_line_before + i
        
        if line_idx_after < #after_lines then
          local line_after = after_lines[line_idx_after + 1] -- Lua tables are 1-indexed
          local line_before = (line_idx_before >= 0 and line_idx_before < #before_lines) 
            and before_lines[line_idx_before + 1] or ""
          
          if line_after ~= line_before then
            -- Find character-level changed ranges
            local changed_ranges = find_changed_ranges(line_before, line_after)
            
            for _, char_range in ipairs(changed_ranges) do
              table.insert(ranges, {
                start_line = line_idx_after,
                start_col = char_range.start_col,
                end_line = line_idx_after,
                end_col = char_range.end_col,
              })
            end
          end
        end
      end
    end
  end

  if #ranges > 0 and callback then
    callback(ranges)
  end
end

---Captures buffer state before an operation and compares after to find changes
---@param callback function Function to call with changed ranges
---@return function Function that triggers the comparison and calls callback
function M.create_diff_detector(callback)
  local bufnr = vim.api.nvim_get_current_buf()
  local before_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local before_tick = vim.api.nvim_buf_get_changedtick(bufnr)

  return function()
    vim.schedule(function()
      M.compare_and_animate(bufnr, before_lines, before_tick, callback)
    end)
  end
end

return M

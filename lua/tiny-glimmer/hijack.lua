local M = {}

---Adds count and register information to the key sequence
---@param key_sequence string The key sequence to modify
---@return string Modified key sequence with count and register
local function add_count_and_registers(key_sequence)
  local modified_keys = vim.api.nvim_replace_termcodes(key_sequence, true, false, true)

  if vim.v.register ~= nil then
    modified_keys = '"' .. vim.v.register .. modified_keys
  end

  if vim.v.count > 1 then
    modified_keys = vim.v.count .. modified_keys
  end

  return modified_keys
end

---Executes a command multiple times based on count
---@param command string|function The command to execute
local function execute_with_count(command)
  for _ = 1, vim.v.count1 do
    if type(command) == "string" then
      vim.cmd(command)
    else
      command()
    end
  end
end

---Hijacks a key mapping with custom behavior
---@param mode string The mode to hijack
---@param map string The key mapping to hijack
---@param original_mapping table The original mapping details
---@param command string|function|nil Additional command to execute
function M.hijack(mode, lhs, rhs, command)
  mode = mode:gsub("%s+", "")
  if mode == nil or mode == "" then
    mode = "n"
  end
  local existing_mapping = vim.fn.maparg(lhs, mode, false, true)

  -- Skip hijacking if the existing mapping uses <SID> to avoid script context errors
  if existing_mapping and existing_mapping.rhs and existing_mapping.rhs:find("<SID>") then
    return
  end

  vim.keymap.set(mode, lhs, function()
    -- When a macro is executing, completely bypass the hijack and use original behavior
    if vim.fn.reg_executing() ~= "" then
      if existing_mapping and existing_mapping.callback then
        existing_mapping.callback()
     elseif existing_mapping and existing_mapping.rhs then
       vim.api.nvim_feedkeys(add_count_and_registers(existing_mapping.rhs), "n", true)
      else
        vim.api.nvim_exec2("normal! " .. lhs, {})
      end
      return
    end

    if command then
      execute_with_count(command)
    end

    if existing_mapping and existing_mapping.callback then
      for _ = 1, vim.v.count1 do
        existing_mapping.callback()
      end
    elseif existing_mapping and existing_mapping.rhs then
      vim.api.nvim_feedkeys(add_count_and_registers(existing_mapping.rhs), "n", true)
    else
      vim.api.nvim_feedkeys(add_count_and_registers(lhs), "n", true)
    end
  end, {
    noremap = true,
  })
end

return M

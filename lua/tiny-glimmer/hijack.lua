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

---Executes the original callback mapping
---@param callback function The callback to execute
---@param key_combination string The key combination
---@param mapping_mode string The mapping mode
---@param original_mapping table The original mapping details
---@param new_rhs string|nil The new right-hand side mapping
---@param command string|function|nil Additional command to execute
local function execute_callback_mapping(callback, key_combination, mapping_mode, original_mapping, new_rhs, command)
	execute_with_count(callback)

	-- Check if mapping changed and rehijack if necessary
	local current_mapping = vim.fn.maparg(key_combination, mapping_mode, false, true)
	if not vim.deep_equal(current_mapping, original_mapping.callback) then
		M.hijack(new_rhs, original_mapping, command)
	end
end

---Executes the right-hand side mapping
---@param rhs string The right-hand side mapping
---@param mode string The mapping mode
local function execute_rhs_mapping(rhs, mode)
	vim.api.nvim_feedkeys(add_count_and_registers(rhs), mode, false)
end

---Creates the mapping execution function
---@param new_rhs string|nil The new right-hand side mapping
---@param original_mapping table The original mapping details
---@param command string|function|nil Additional command to execute
---@return function The mapping execution function
local function create_mapping_executor(new_rhs, original_mapping, command)
	local key_combination = original_mapping.lhs
	local mapping_mode = original_mapping.mode

	return function()
		-- Handle original mapping
		if original_mapping and not vim.tbl_isempty(original_mapping) then
			if original_mapping.callback then
				execute_callback_mapping(
					original_mapping.callback,
					key_combination,
					mapping_mode,
					original_mapping,
					new_rhs,
					command
				)
			elseif original_mapping.rhs then
				execute_rhs_mapping(original_mapping.rhs, original_mapping.mode)
			end
		elseif new_rhs and type(new_rhs) == "string" then
			execute_rhs_mapping(new_rhs, mapping_mode)
		end

		-- Execute additional command if provided
		if command then
			execute_with_count(command)
		end
	end
end

---Hijacks a key mapping with custom behavior
---@param new_rhs string|nil The new right-hand side mapping
---@param original_mapping table The original mapping details
---@param command string|function|nil Additional command to execute
function M.hijack(new_rhs, original_mapping, command)
	local key_combination = original_mapping.lhs
	local mapping_mode = original_mapping.mode

	local execute_mapping = create_mapping_executor(new_rhs, original_mapping, command)

	-- Set up the new mapping
	vim.keymap.set(mapping_mode, key_combination, execute_mapping, {
		noremap = true,
		silent = true,
	})
end

return M

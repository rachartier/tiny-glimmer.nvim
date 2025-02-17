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
---@param lhs string The left-hand side mapping
---@param rhs string The right-hand side mapping
---@param mapping_mode string The mapping mode
---@param original_mapping table|string The original mapping details
---@param command string|function|nil Additional command to execute
local function execute_callback_mapping(callback, lhs, rhs, mapping_mode, original_mapping, command)
	execute_with_count(callback)

	-- Check if mapping changed and rehijack if necessary
	local current_mapping = vim.fn.maparg(lhs, mapping_mode, false, true)
	if not vim.deep_equal(current_mapping, original_mapping.callback) then
		M.hijack(mapping_mode, lhs, rhs, original_mapping, command)
	end
end

---Creates the mapping execution function
---@param lhs string The left-hand side mapping
---@param rhs string The right-hand side mapping
---@param mode string The mode of the mapping
---@param original_mapping table The original mapping details
---@return function The mapping execution function
local function create_mapping_executor(lhs, rhs, mode, original_mapping, command)
	return function()
		if original_mapping and not vim.tbl_isempty(original_mapping) then
			local mapping_mode = original_mapping.mode

			if original_mapping.callback then
				execute_callback_mapping(
					original_mapping.callback,
					original_mapping.lhs,
					original_mapping.rhs,
					mapping_mode,
					original_mapping,
					command
				)
			elseif original_mapping.rhs then
				vim.api.nvim_feedkeys(add_count_and_registers(original_mapping.rhs), original_mapping.mode, false)
			end
		elseif rhs then
			vim.api.nvim_feedkeys(add_count_and_registers(rhs), mode, false)
		elseif lhs then
			vim.api.nvim_feedkeys(add_count_and_registers(lhs), mode, false)
		end

		-- Execute additional command if provided
		if command then
			execute_with_count(command)
		end
	end
end

---Hijacks a key mapping with custom behavior
---@param mode string The mode to hijack
---@param map string The key mapping to hijack
---@param original_mapping table The original mapping details
---@param command string|function|nil Additional command to execute
function M.hijack(mode, lhs, rhs, original_mapping, command)
	local execute_mapping = create_mapping_executor(lhs, rhs, mode, original_mapping, command)

	-- remove mode whitespaces
	mode = mode:gsub("%s+", "")
	if mode == nil or mode == "" then
		mode = "n"
	end

	-- Set up the new mapping
	vim.keymap.set(mode, lhs, execute_mapping, {
		noremap = true,
		silent = true,
	})
end

return M

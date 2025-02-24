local M = {}

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
function M.hijack(mode, lhs, rhs, original_mapping, command)
	mode = mode:gsub("%s+", "")
	if mode == nil or mode == "" then
		mode = "n"
	end
	local existing_mapping = vim.fn.maparg(lhs, "n", false, true)

	vim.api.nvim_set_keymap(mode, lhs, "", {
		noremap = true,
		callback = function()
			if command then
				execute_with_count(command)
			end

			if existing_mapping and existing_mapping.callback then
				existing_mapping.callback()
			elseif existing_mapping and existing_mapping.rhs then
				vim.api.nvim_feedkeys(
					vim.api.nvim_replace_termcodes(existing_mapping.rhs, true, false, true),
					"n",
					true
				)
			else
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), "n", true)
			end
		end,
	})
end

return M

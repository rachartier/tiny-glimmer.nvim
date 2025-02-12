local M = {}

---@param opts table Animation options
---@return nil
local function handle_text_change_animation(opts)
	local detach_listener = false

	---Callback function for buffer changes
	---@param event any Event type
	---@param bufnr number Buffer number
	---@param changedtick number Changed tick
	---@param start_row number Starting row of change
	---@param start_col number Starting column of change
	---@param byte_offset number Byte offset
	---@param old_end_row number Old end row
	---@param old_end_col number Old end column
	---@param old_byte_end number Old end byte
	---@param new_end_row number New end row
	---@param new_end_col number New end column
	---@param new_byte_end number New end byte
	function M.on_bytes(
		event,
		bufnr,
		changedtick,
		start_row,
		start_col,
		byte_offset,
		old_end_row,
		old_end_col,
		old_byte_end,
		new_end_row,
		new_end_col,
		new_byte_end
	)
		if detach_listener then
			return true
		end

		-- Calculate the affected text range
		local buffer_line_count = vim.api.nvim_buf_line_count(0)
		local end_row = start_row + new_end_row
		local end_col = start_col + new_end_col

		-- Adjust end column for changes at buffer end
		if end_row >= buffer_line_count then
			local last_line = vim.api.nvim_buf_get_lines(0, -2, -1, false)[1]
			end_col = #last_line
		end

		vim.schedule(function()
			local range = {
				start_line = start_row,
				start_col = start_col,
				end_line = end_row,
				end_col = end_col,
			}

			local changed_text = vim.api.nvim_buf_get_lines(0, start_row, end_row, false)

			require("tiny-glimmer.animation.factory").get_instance():create_text_animation(opts.default_animation, {
				base = { range = range },
				is_paste = true,
				content = changed_text,
			})

			detach_listener = true
		end)
	end

	-- Attach buffer listener
	vim.api.nvim_buf_attach(0, false, {
		on_bytes = M.on_bytes,
	})
end

---Animate undo operation
---@param opts table Animation options
function M.undo(opts)
	handle_text_change_animation(opts)
end

---Animate redo operation
---@param opts table Animation options
function M.redo(opts)
	handle_text_change_animation(opts)
end

return M

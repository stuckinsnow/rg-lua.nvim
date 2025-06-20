local M = {}

-- Helper function to safely close existing buffer by name
function M.close_existing_buffer(name_pattern)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) then
			local buf_name = vim.api.nvim_buf_get_name(buf)
			if buf_name:find(name_pattern, 1, true) then
				-- Close any windows showing this buffer first
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
						vim.api.nvim_win_close(win, true)
					end
				end
				-- Delete the buffer
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end
	end
end

-- Helper to create side buffer with common setup
function M.create_side_buffer(prefix, width_percent, filetype)
	width_percent = width_percent or 0.5
	filetype = filetype or "markdown"

	M.close_existing_buffer(prefix)

	vim.cmd("rightbelow vertical split")
	local win = vim.api.nvim_get_current_win()
	local width = math.floor(vim.o.columns * width_percent)
	vim.api.nvim_win_set_width(win, width)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, prefix)
	vim.bo[buf].filetype = filetype
	vim.api.nvim_win_set_buf(win, buf)

	vim.wo[win].signcolumn = "no"
	vim.wo[win].wrap = true

	return win, buf
end

return M

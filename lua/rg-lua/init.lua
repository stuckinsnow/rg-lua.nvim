local M = {}

-- Store configuration globally
M.config = {
	width_percent = 0.5, -- default width
}

function M.setup(opts)
	opts = opts or {}

	-- Merge user config with defaults
	M.config = vim.tbl_deep_extend("force", M.config, opts)

	-- Check dependencies
	if not M.check_dependencies() then
		return
	end

	-- Setup search functionality
	require("rg-lua.search").setup()
end

function M.search()
	require("rg-lua.search").search_files()
end

function M.check_dependencies()
	local dependencies = {
		{ cmd = "rg", name = "ripgrep" },
	}

	for _, dep in ipairs(dependencies) do
		if vim.fn.executable(dep.cmd) == 0 then
			vim.notify(dep.name .. " is not installed or not in PATH", vim.log.levels.ERROR)
			return false
		end
	end
	return true
end

return M

local M = {}
local ui = require("rg-lua.ui")
local ripgrep = require("rg-lua.ripgrep")
local results = require("rg-lua.results")
local spinner = require("rg-lua.spinner")

function M.search_files()
	local search_terms = ui.get_search_input()
	if not search_terms then
		vim.notify("Search cancelled - no terms provided", vim.log.levels.INFO)
		return
	end

	ui.get_search_mode(search_terms, function(search_mode)
		M.perform_search(search_terms, search_mode)
	end)
end

function M.perform_search(search_terms, search_mode)
	spinner.show_loading("Searching files...")

	local cmd = ripgrep.build_search_command(search_terms, search_mode)
	local unique = search_mode:match("Unique") or search_mode == "Unique"

	ripgrep.execute_search(cmd, function(result)
		vim.schedule(function()
			spinner.hide_loading()

			if result.code ~= 0 then
				vim.notify("No matches found", vim.log.levels.INFO)
				return
			end

			local output = result.stdout or ""
			if output == "" then
				vim.notify("No matches found", vim.log.levels.INFO)
				return
			end

			-- Process unique results if needed
			if unique then
				output = results.make_unique(output)
			end

			-- Get file list
			M.get_file_list(search_terms, search_mode, function(files)
				local markdown_lines = results.create_markdown_output(output, files, search_terms, search_mode)
				ui.show_results_buffer(markdown_lines, files, search_terms)
			end)
		end)
	end)
end

function M.get_file_list(search_terms, search_mode, callback)
	local cmd = ripgrep.build_file_list_command(search_terms, search_mode)
	local unique = search_mode:match("Unique") or search_mode == "Unique"

	ripgrep.execute_search(cmd, function(result)
		local files = results.process_file_list(result, unique)
		vim.schedule(function()
			callback(files)
		end)
	end)
end

function M.setup()
	vim.api.nvim_create_user_command("RgSearch", function()
		M.search_files()
	end, { desc = "Search files with ripgrep" })
end

return M

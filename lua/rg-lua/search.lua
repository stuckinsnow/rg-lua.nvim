local M = {}
local utils = require("rg-lua.utils")

function M.search_files()
	-- Get search terms
	local search_input = vim.fn.input("Search terms (space-separated): ")
	if not search_input or search_input:match("^%s*$") then
		vim.notify("Search cancelled - no terms provided", vim.log.levels.INFO)
		return
	end

	-- Parse search terms
	local search_terms = {}
	for term in search_input:gmatch("%S+") do
		table.insert(search_terms, term)
	end

	if #search_terms == 0 then
		vim.notify("No search terms provided", vim.log.levels.ERROR)
		return
	end

	-- Choose search mode based on number of terms
	if #search_terms == 1 then
		-- Single term - only ask about unique
		vim.ui.select({ "All Results", "Unique Files Only" }, {
			prompt = "Result mode:",
			format_item = function(item)
				return item
			end,
		}, function(result_mode)
			if not result_mode then
				return
			end

			local search_mode = result_mode == "Unique Files Only" and "Unique" or "All"
			M.perform_search(search_terms, search_mode)
		end)
	else
		-- Multiple terms - ask about AND/OR and unique
		vim.ui.select({ "OR Search", "AND Search", "Unique OR", "Unique AND" }, {
			prompt = "Search mode:",
			format_item = function(item)
				return item
			end,
		}, function(search_mode)
			if not search_mode then
				return
			end

			M.perform_search(search_terms, search_mode)
		end)
	end
end

function M.perform_search(search_terms, search_mode)
	local spinner = require("rg-lua.spinner")
	spinner.show_loading("Searching files...")

	local cmd
	local unique = search_mode:match("Unique") or search_mode == "Unique"
	local and_search = search_mode:match("AND")

	if #search_terms == 1 then
		-- Single term search
		cmd = { "rg", "--color=always", search_terms[1], "." }
	elseif and_search then
		-- Build regex pattern exactly like your bash function
		local pattern = ""
		for _, term in ipairs(search_terms) do
			pattern = pattern .. "(?=.*" .. term .. ")"
		end
		pattern = pattern .. ".*"

		cmd = { "rg", "--color=always", "-P", pattern, "." }
	else
		-- OR search - join terms with |
		local pattern = table.concat(search_terms, "|")
		cmd = { "rg", "--color=always", pattern, "." }
	end

	-- Execute search
	vim.system(cmd, { text = true }, function(result)
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
				output = M.make_unique(output)
			end

			-- Get file list
			M.get_file_list(search_terms, search_mode, function(files)
				M.create_markdown_output(output, files, search_terms, search_mode)
			end)
		end)
	end)
end

function M.make_unique(output)
	local lines = vim.split(output, "\n")
	local seen_files = {}
	local unique_lines = {}

	for _, line in ipairs(lines) do
		if line ~= "" then
			local file_path = line:match("^([^:]+):")
			if file_path and not seen_files[file_path] then
				seen_files[file_path] = true
				table.insert(unique_lines, line)
			end
		end
	end

	return table.concat(unique_lines, "\n")
end

function M.get_file_list(search_terms, search_mode, callback)
	local unique = search_mode:match("Unique") or search_mode == "Unique"
	local and_search = search_mode:match("AND")

	local cmd
	if #search_terms == 1 then
		-- Single term
		cmd = { "rg", "-l", search_terms[1], "." }
	elseif and_search then
		local pattern = ""
		for _, term in ipairs(search_terms) do
			pattern = pattern .. "(?=.*" .. term .. ")"
		end
		pattern = pattern .. ".*"
		cmd = { "rg", "-l", "-P", pattern, "." }
	else
		local pattern = table.concat(search_terms, "|")
		cmd = { "rg", "-l", pattern, "." }
	end

	vim.system(cmd, { text = true }, function(result)
		local files = {}
		if result.code == 0 and result.stdout then
			local file_lines = vim.split(result.stdout, "\n")
			for _, file in ipairs(file_lines) do
				if file ~= "" then
					table.insert(files, file)
				end
			end

			if unique then
				-- Sort and make unique
				table.sort(files)
				local unique_files = {}
				local seen = {}
				for _, file in ipairs(files) do
					if not seen[file] then
						seen[file] = true
						table.insert(unique_files, file)
					end
				end
				files = unique_files
			end
		end

		vim.schedule(function()
			callback(files)
		end)
	end)
end

function M.create_markdown_output(search_output, files, search_terms, search_mode)
	local lines = {}

	-- Header
	table.insert(lines, "# Search Results")
	table.insert(lines, "")
	table.insert(lines, string.format("**Search Terms:** %s", table.concat(search_terms, " ")))
	table.insert(lines, string.format("**Search Mode:** %s", search_mode))
	table.insert(lines, string.format("**Date:** %s", os.date("%Y-%m-%d %H:%M:%S")))
	table.insert(lines, "")

	-- Files found section
	table.insert(lines, string.format("## 📁 Found %d files:", #files))
	table.insert(lines, "")
	for _, file in ipairs(files) do
		table.insert(lines, string.format("- `%s`", file))
	end
	table.insert(lines, "")

	-- Search results section
	table.insert(lines, "## Search Results")
	table.insert(lines, "")
	table.insert(lines, "```")

	-- Add search output, removing ANSI codes for markdown
	local clean_output = search_output:gsub("\27%[[0-9;]*m", "")
	local output_lines = vim.split(clean_output, "\n")
	for _, line in ipairs(output_lines) do
		if line ~= "" then
			table.insert(lines, line)
		end
	end

	table.insert(lines, "```")
	table.insert(lines, "")

	-- Show in buffer
	M.show_results_buffer(lines, files, search_terms)
end

function M.show_results_buffer(markdown_lines, files, search_terms)
	local win, buf = utils.create_side_buffer("search_results", 0.7, "markdown")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, markdown_lines)
	vim.bo[buf].modifiable = false

	-- Add keymaps
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf, nowait = true, desc = "Close search results" })

	-- Open files with fzf
	vim.keymap.set("n", "<CR>", function()
		if #files == 0 then
			vim.notify("No files to open", vim.log.levels.WARN)
			return
		end

		require("fzf-lua").fzf_exec(files, {
			prompt = "Open File> ",
			fzf_opts = {
				["--header"] = string.format("Files from search: %s", table.concat(search_terms, " ")),
			},
			actions = {
				["default"] = function(selected)
					if selected and #selected > 0 then
						vim.cmd("edit " .. vim.fn.fnameescape(selected[1]))
					end
				end,
			},
		})
	end, { buffer = buf, nowait = true, desc = "Open file picker" })

	-- Save to file
	vim.keymap.set("n", "s", function()
		local filename = vim.fn.input("Save to file: ", "search_results_" .. os.date("%Y%m%d_%H%M%S") .. ".md")
		if filename and filename ~= "" then
			local file = io.open(filename, "w")
			if file then
				for _, line in ipairs(markdown_lines) do
					file:write(line .. "\n")
				end
				file:close()
				vim.notify("Results saved to " .. filename, vim.log.levels.INFO)
			else
				vim.notify("Failed to save file", vim.log.levels.ERROR)
			end
		end
	end, { buffer = buf, nowait = true, desc = "Save to file" })

	vim.notify(
		string.format("Search results: %d files | <CR>=pick file, s=save to file, q=close", #files),
		vim.log.levels.INFO
	)
end

function M.setup()
	vim.api.nvim_create_user_command("RgSearch", function()
		M.search_files()
	end, { desc = "Search files with ripgrep" })
end

return M

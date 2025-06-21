local M = {}

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

function M.process_file_list(result, unique)
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
	return files
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

	return lines
end

return M

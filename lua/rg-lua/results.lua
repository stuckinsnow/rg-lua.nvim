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

function M.create_interactive_output(search_output, files, search_terms, search_mode)
	local lines = {}

	-- Header
	table.insert(lines, "Search Terms: " .. table.concat(search_terms, " "))
	table.insert(lines, "Search Mode: " .. search_mode)
	table.insert(lines, "Date: " .. os.date("%Y-%m-%d %H:%M:%S"))
	table.insert(lines, "")

	-- Simple file list
	table.insert(lines, string.format("Found %d files:", #files))
	for _, file in ipairs(files) do
		table.insert(lines, file)
	end
	table.insert(lines, "")

	-- Process search output to group by file
	local clean_output = search_output:gsub("\27%[[0-9;]*m", "")
	local output_lines = vim.split(clean_output, "\n")

	-- Group results by file
	local file_results = {}
	local file_order = {} -- Track order of files as they appear

	for _, line in ipairs(output_lines) do
		if line ~= "" then
			-- Extract file path, line number, and content
			local file_path, line_num, content = line:match("^([^:]+):(%d+):(.*)")
			if file_path and line_num and content then
				if not file_results[file_path] then
					file_results[file_path] = {}
					table.insert(file_order, file_path)
				end
				-- Store line number and content
				table.insert(file_results[file_path], {
					line_num = line_num,
					content = content,
				})
			end
		end
	end

	-- Add grouped results in grug-far style
	for _, file_path in ipairs(file_order) do
		-- Add filename
		table.insert(lines, file_path)

		-- Add results for this file with line numbers
		for _, result in ipairs(file_results[file_path]) do
			table.insert(lines, string.format("%s:%s", result.line_num, result.content))
		end
		table.insert(lines, "")
	end

	return lines
end

return M

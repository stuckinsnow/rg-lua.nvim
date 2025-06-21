local M = {}

function M.build_search_command(search_terms, search_mode)
	local and_search = search_mode:match("AND")

	if #search_terms == 1 then
		-- Single term search
		return { "rg", "--color=always", "-i", search_terms[1], "." }
	elseif and_search then
		-- Build regex pattern for AND search - must contain ALL terms
		local pattern = "^"
		for _, term in ipairs(search_terms) do
			pattern = pattern .. "(?=.*" .. vim.pesc(term) .. ")"
		end
		pattern = pattern .. ".*$"

		return { "rg", "--color=always", "-i", "-P", pattern, "." }
	else
		-- OR search - join terms with |
		local escaped_terms = {}
		for _, term in ipairs(search_terms) do
			table.insert(escaped_terms, vim.pesc(term))
		end
		local pattern = table.concat(escaped_terms, "|")
		return { "rg", "--color=always", "-i", pattern, "." }
	end
end

function M.build_file_list_command(search_terms, search_mode)
	local and_search = search_mode:match("AND")

	if #search_terms == 1 then
		-- Single term
		return { "rg", "-l", "-i", search_terms[1], "." }
	elseif and_search then
		local pattern = "^"
		for _, term in ipairs(search_terms) do
			pattern = pattern .. "(?=.*" .. vim.pesc(term) .. ")"
		end
		pattern = pattern .. ".*$"
		return { "rg", "-l", "-i", "-P", pattern, "." }
	else
		local escaped_terms = {}
		for _, term in ipairs(search_terms) do
			table.insert(escaped_terms, vim.pesc(term))
		end
		local pattern = table.concat(escaped_terms, "|")
		return { "rg", "-l", "-i", pattern, "." }
	end
end

function M.execute_search(cmd, callback)
	vim.system(cmd, { text = true }, callback)
end

return M

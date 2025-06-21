local M = {}
local utils = require("rg-lua.utils")

function M.get_search_input()
	-- Get search terms
	local search_input = vim.fn.input("Search terms (space-separated): ")
	if not search_input or search_input:match("^%s*$") then
		return nil
	end

	-- Parse search terms
	local search_terms = {}
	for term in search_input:gmatch("%S+") do
		table.insert(search_terms, term)
	end

	if #search_terms == 0 then
		return nil
	end

	return search_terms
end

function M.get_search_mode(search_terms, callback)
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
			callback(search_mode)
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

			callback(search_mode)
		end)
	end
end

function M.show_results_buffer(markdown_lines, files, search_terms)
	local win, buf = utils.create_results_buffer("search_results", "rg-results")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, markdown_lines)
	vim.bo[buf].modifiable = false

	-- Set up custom syntax highlighting
	M.setup_syntax_highlighting(buf)

	-- Add dynamic highlighting for search terms
	M.highlight_search_terms(buf, search_terms)

	-- Rest of your existing keymap code...
	vim.keymap.set("n", "q", function()
		local rg_lua = require("rg-lua")
		if rg_lua.config.use_main_buffer then
			-- For main buffer mode: switch to alternate buffer or create new one
			local alt_buf = vim.fn.bufnr("#")
			if alt_buf ~= -1 and vim.api.nvim_buf_is_valid(alt_buf) and alt_buf ~= buf then
				vim.api.nvim_win_set_buf(win, alt_buf)
			else
				-- No valid alternate buffer, create a new empty one
				local new_buf = vim.api.nvim_create_buf(true, false)
				vim.api.nvim_win_set_buf(win, new_buf)
			end
			-- Clean up the search results buffer
			vim.api.nvim_buf_delete(buf, { force = true })
		else
			-- For side buffer mode: close the window as before
			vim.api.nvim_win_close(win, true)
		end
	end, { buffer = buf, nowait = true, desc = "Close search results" })

	vim.keymap.set("n", "<CR>", function()
		if #files == 0 then
			vim.notify("No files to open", vim.log.levels.WARN)
			return
		end

		require("fzf-lua").fzf_exec(files, {
			prompt = "Open File> ",
			fzf_opts = {
				["--header"] = string.format("Files from search: %s", table.concat(search_terms, " ")),
				["--multi"] = true,
			},
			preview = require("fzf-lua").shell.raw_preview_action_cmd(function(items)
				return string.format(
					"bat --style=numbers --color=always --line-range=:100 %s 2>/dev/null || cat %s 2>/dev/null || echo '[File not readable]'",
					vim.fn.shellescape(items[1]),
					vim.fn.shellescape(items[1])
				)
			end),
			actions = {
				["default"] = function(selected)
					if selected and #selected > 0 then
						vim.cmd("edit " .. vim.fn.fnameescape(selected[1]))
					end
				end,
			},
		})
	end, { buffer = buf, nowait = true, desc = "Open file picker" })

	vim.keymap.set("n", "s", function()
		local filename = vim.fn.input("Save to file: ", "search_results_" .. os.date("%Y%m%d_%H%M%S") .. ".txt")
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

	local rg_lua = require("rg-lua")
	local buffer_type = rg_lua.config.use_main_buffer and "main buffer" or "side buffer"

	vim.notify(
		string.format("Search results in %s: %d files | <CR>=pick file, s=save to file, q=close", buffer_type, #files),
		vim.log.levels.INFO
	)
end

function M.setup_syntax_highlighting(buf)
	-- Set up syntax matching
	vim.api.nvim_buf_call(buf, function()
		-- Clear any existing syntax
		vim.cmd("syntax clear")

		-- Highlight header lines first
		vim.cmd([[syntax match RgResultsHeader "^Search Terms:.*$"]])
		vim.cmd([[syntax match RgResultsHeader "^Search Mode:.*$"]])
		vim.cmd([[syntax match RgResultsHeader "^Date:.*$"]])
		vim.cmd([[syntax match RgResultsHeader "^Found \d\+ files:$"]])

		-- Highlight file paths (lines that start with ./ and don't contain line numbers)
		vim.cmd([[syntax match RgResultsFile "^\./[^:]*$"]])

		-- Highlight files in the file list section
		vim.cmd([[syntax match RgResultsFileList "^\./.*" contained]])

		-- Highlight normal content text (lines that start with line numbers)
		vim.cmd([[syntax match RgResultsContent "^\d\+:.*$"]])
	end)
end

function M.highlight_search_terms(buf, search_terms)
	vim.api.nvim_buf_call(buf, function()
		-- Clear existing content highlighting
		vim.cmd([[syntax clear RgResultsContent]])
		vim.cmd([[syntax clear RgResultsMatch]])

		-- Define search term matches (all use same group name)
		for _, term in ipairs(search_terms) do
			local escaped_term = vim.fn.escape(term, "\\[]^$.*~")
			vim.cmd(string.format([[syntax match RgResultsMatch "\c%s"]], escaped_term))
		end

		-- Define line number pattern
		vim.cmd([[syntax match RgResultsLineNr "^\d\+:" contained]])

		-- Define content pattern that contains the other patterns
		vim.cmd([[syntax match RgResultsContent "^\d\+:.*$" contains=RgResultsLineNr,RgResultsMatch]])
	end)
end

return M

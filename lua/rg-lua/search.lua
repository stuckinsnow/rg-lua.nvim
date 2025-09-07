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
				local markdown_lines = results.create_interactive_output(output, files, search_terms, search_mode)
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

function M.search_files_prompt()
	vim.ui.input({ prompt = "Search terms (space-separated): " }, function(search_input)
		if not search_input or search_input == "" then
			return
		end

		local search_terms = {}
		for term in search_input:gmatch("%S+") do
			table.insert(search_terms, term)
		end
		if #search_terms == 0 then
			return
		end

		local modes = { "OR Search", "AND Search" }
		require("fzf-lua").fzf_exec(modes, {
			prompt = "Search mode> ",
			winopts = { height = 0.15 },
			actions = {
				["default"] = function(selected)
					if not selected or #selected == 0 then
						return
					end
					local search_mode = selected[1]

					local rg_pattern, rg_cmd
					if search_mode == "AND Search" and #search_terms > 1 then
						local pattern = "^"
						for _, term in ipairs(search_terms) do
							pattern = pattern .. "(?=.*" .. vim.pesc(term) .. ")"
						end
						pattern = pattern .. ".*$"
						rg_pattern = pattern
						rg_cmd = string.format(
							"rg --files-with-matches --color=never -P %s .",
							vim.fn.shellescape(rg_pattern)
						)
					else
						local pattern = table.concat(vim.tbl_map(vim.pesc, search_terms), "|")
						rg_pattern = pattern
						rg_cmd =
							string.format("rg --files-with-matches --color=never %s .", vim.fn.shellescape(rg_pattern))
					end

					local preview_pattern = table.concat(vim.tbl_map(vim.pesc, search_terms), "|")
					local preview_cmd = string.format(
						"bat --color=always --style=numbers --paging=never %s 2>/dev/null | grep --color=always -E '%s' || true",
						"{}",
						preview_pattern
					)

					require("fzf-lua").fzf_exec(rg_cmd, {
						prompt = string.format('Files containing "%s"> ', table.concat(search_terms, " ")),
						preview = preview_cmd,
						actions = {
							["default"] = function(files)
								if not files or #files == 0 then
									return
								end
								for i, filepath in ipairs(files) do
									if vim.fn.filereadable(filepath) == 0 then
										vim.notify("File not readable: " .. filepath, vim.log.levels.ERROR)
										goto continue
									end
									if i == 1 then
										vim.cmd("edit " .. vim.fn.fnameescape(filepath))
									else
										vim.cmd("badd " .. vim.fn.fnameescape(filepath))
									end
									if i == 1 then
										local search_pat = table.concat(search_terms, "\\|")
										local search_result = vim.fn.search(search_pat, "w")
										if search_result > 0 then
											vim.cmd("normal! zz")
											vim.fn.setreg("/", table.concat(search_terms, " "))
											vim.opt.hlsearch = true
										end
									end
									::continue::
								end
								if #files > 1 then
									vim.notify(
										string.format("Opened %d files (use :ls to see buffers)", #files),
										vim.log.levels.INFO
									)
								end
							end,
						},
						fzf_opts = {
							["--multi"] = true,
							["--preview-window"] = "right:50%:wrap",
							["--bind"] = "ctrl-/:toggle-preview,tab:down,shift-tab:up,ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle",
							["--cycle"] = true,
						},
					})
				end,
			},
		})
	end)
end

function M.setup()
	vim.api.nvim_create_user_command("RgSearch", function()
		M.search_files()
	end, { desc = "Search files with ripgrep" })
	vim.api.nvim_create_user_command("RgFiles", M.search_files_prompt, { desc = "Ripgrep Search - Prompt" })
end

return M

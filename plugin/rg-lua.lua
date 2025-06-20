-- Auto-setup the plugin
if vim.g.loaded_rg_lua then
	return
end
vim.g.loaded_rg_lua = true

-- Setup the plugin automatically
require("rg-lua").setup()

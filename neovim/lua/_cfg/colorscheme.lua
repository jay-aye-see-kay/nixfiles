local plugins = require("nln").plugins
local h = require("_cfg.helpers")

h.autocmd({ "ColorScheme" }, {
	callback = function()
		local copy_color = function(from, to)
			vim.api.nvim_set_hl(0, to, vim.api.nvim_get_hl_by_name(from, true))
		end
		copy_color("DiffAdd", "diffAdded")
		copy_color("DiffDelete", "diffRemoved")
		copy_color("DiffChange", "diffChanged")
		vim.api.nvim_set_hl(0, "@markup.quote", {})
	end,
})

plugins["catppuccin-nvim"] = {
	lazy = false,
	priority = 1000,
	config = function()
		vim.o.background = "dark"
		require("catppuccin").setup({
			term_colors = true,
			integrations = {
				cmp = true,
				gitsigns = true,
				markdown = true,
				mini = true,
				neotree = true,
				noice = true,
				notify = true,
				semantic_tokens = true,
				telescope = true,
				which_key = true,
				-- For more integrations https://github.com/catppuccin/nvim#integrations
			},
			custom_highlights = function(colors)
				return {
					ActiveTerm = { bg = colors.crust },
				}
			end,
		})
		vim.cmd.colorscheme("catppuccin-macchiato") -- latte, frappe, macchiato, mocha
	end,
}

local h = require("config.helpers")

-- Colorscheme post-load autocmd
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

-- Colorscheme configuration
return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		config = function()
			vim.o.background = "dark"
			require("catppuccin").setup({
				flavour = "macchiato", -- latte, frappe, macchiato, mocha
				term_colors = true,
				transparent_background = false,
				integrations = {
					cmp = true,
					gitsigns = true,
					markdown = true,
					mini = true,
					neotree = true,
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
			vim.cmd.colorscheme("catppuccin-macchiato")
		end,
	},
}

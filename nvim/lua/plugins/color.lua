return {
	{
		"catppuccin/nvim",
		lazy = false, -- make sure we load this during startup if it is your main colorscheme
		priority = 1000, -- make sure to load this before all the other start plugins
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

			-- should prob be somewhere else
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
		end,
	},
}

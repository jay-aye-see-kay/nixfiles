return {
	{
		"projekt0n/github-nvim-theme",
		name = "github-theme",
		lazy = false,
		priority = 1000,
		config = function()
			require("github-theme").setup({
				options = { transparent = true },
				-- lualine fills inactive winbars with StatusLineNC, which the theme
				-- keeps solid white even when transparent
				groups = { all = { StatusLineNC = { bg = "NONE" } } },
			})
			vim.cmd("colorscheme github_light")
		end,
	},
}

return {
	{
		"opdavies/toggle-checkbox.nvim",
		lazy = true,
		cmd = "ToggleCheckbox",
		keys = {
			{ "\\\\", "<cmd>lua require('toggle-checkbox').toggle()<cr>", desc = "Toggle Checkbox" },
		},
	},

	{
		"lukas-reineke/headlines.nvim",
		lazy = true,
		ft = { "markdown", "rmd", "orgmode", "neorg" },
		opts = {
			markdown = { fat_headlines = false },
			rmd = { fat_headlines = false },
			norg = { fat_headlines = false },
			org = { fat_headlines = false },
		},
	},
}

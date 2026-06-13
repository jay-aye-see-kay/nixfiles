return {
	{
		"stevearc/quicker.nvim",
		ft = "qf",
		---@module "quicker"
		---@type quicker.SetupOptions
		opts = {},
		keys = {
			{
				"<leader>q",
				function()
					require("quicker").toggle()
				end,
				desc = "Toggle quickfix",
			},
			{
				"<",
				function()
					require("quicker").collapse()
				end,
				ft = "qf",
				desc = "Collapse quickfix context",
			},
			{
				">",
				function()
					require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
				end,
				ft = "qf",
				desc = "Expand quickfix context",
			},
		},
	},
}

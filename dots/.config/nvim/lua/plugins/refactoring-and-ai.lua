return {
	{
		"zbirenbaum/copilot.lua",
		lazy = true,
		cmd = { "Copilot" },
		event = "InsertEnter",
		keys = {
			{ "<C-d>", mode = "i" },
			{
				"<leader>cc",
				function()
					if require("copilot.client").is_disabled() then
						vim.cmd("Copilot enable")
						print("copilot enabled")
					else
						vim.cmd("Copilot disable")
						print("copilot disabled")
					end
				end,
				desc = "toggle copilot globally",
			},
		},
		config = function()
			require("copilot").setup({
				panel = {
					enabled = false,
				},
				suggestion = {
					keymap = {
						accept = "<C-f>", -- like fish
						next = "<C-d>", -- also triggers when not on auto
						prev = "<C-s>",
					},
				},
			})
			vim.cmd("Copilot disable") -- enable on demand
		end,
	},

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

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
		"folke/sidekick.nvim",
		opts = {
			nes = { enabled = false },
			cli = {
				mux = {
					backend = "tmux",
					enabled = true,
				},
			},
		},
		keys = {
			{
				",s",
				function()
					require("sidekick.cli").toggle({ name = "opencode", focus = true })
				end,
				desc = "Sidekick Toggle Opencode",
			},
		},
	},

	{
		"carlos-algms/agentic.nvim",
		config = function()
			require("agentic").setup({
				provider = "opencode-acp",
			})
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "AgenticInput",
				callback = function()
					vim.keymap.set("n", "ZZ", "<Nop>", { buffer = true })
				end,
			})
		end,
		keys = {
			{
				"<C-\\>",
				function()
					require("agentic").toggle()
				end,
				mode = { "n", "v", "i" },
				desc = "Toggle Agentic Chat",
			},
			{
				"<C-'>", -- note: not currently working through tmux
				function()
					require("agentic").add_selection_or_file_to_context()
				end,
				mode = { "n", "v" },
				desc = "Add file or selection to Agentic to Context",
			},
			{
				"<leader>an",
				function()
					require("agentic").new_session()
				end,
				mode = { "n", "v" },
				desc = "New Agentic Session",
			},
			{
				"<leader>ar",
				function()
					require("agentic").restore_session()
				end,
				mode = { "n" },
				desc = "Agentic Sessions",
			},
			{
				"<leader>as",
				function()
					require("agentic").stop_generation()
				end,
				mode = { "n" },
				desc = "Agentic Stop",
			},
		},
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

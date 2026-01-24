-- DAP and debugging tools
return {
	-- Debug print statements
	{
		"andrewferrier/debugprint.nvim",
		lazy = true,
		event = "VeryLazy",
		opts = {
			print_tag = "DEBUG",
			display_location = false,
			filetypes = {
				["go"] = {
					left = 'fmt.Printf("',
					right = '\\n")',
					mid_var = '%+v\\n", ',
					right_var = ")",
				},
			},
		},
	},

	-- DAP UI
	{
		"rcarriga/nvim-dap-ui",
		lazy = true,
		opts = {},
	},

	-- DAP virtual text
	{
		"theHamsta/nvim-dap-virtual-text",
		lazy = true,
		opts = { virt_text_pos = "eol" },
	},

	-- DAP Go adapter
	{
		"leoluz/nvim-dap-go",
		lazy = true,
		opts = {},
	},

	-- DAP Python adapter
	{
		"mfussenegger/nvim-dap-python",
		lazy = true,
		config = function()
			require("dap-python").setup(vim.g.python3_host_prog)
		end,
	},

	-- Main DAP plugin
	{
		"mfussenegger/nvim-dap",
		lazy = true,
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
			"leoluz/nvim-dap-go",
			"mfussenegger/nvim-dap-python",
		},
		keys = {
			{
				"<space>dR",
				function()
					require("dap").clear_breakpoints()
				end,
				desc = "clear breakpoints",
			},
			{
				"<space>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "toggle breakpoint",
			},
			{
				"<space>dc",
				function()
					require("dap").continue()
				end,
				desc = "continue",
			},
			{
				"<space>dr",
				function()
					require("dap").repl.open()
				end,
				desc = "repl",
			},
			{
				"<space>di",
				function()
					require("dap").step_into()
				end,
				desc = "step into",
			},
			{
				"<space>do",
				function()
					require("dap").step_over()
				end,
				desc = "step over",
			},
			{
				"<space>dt",
				function()
					require("dap").step_out()
				end,
				desc = "step out",
			},
			{
				"<space>du",
				function()
					require("dapui").toggle()
				end,
				desc = "toggle",
			},
			{
				"<space>dC",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "run to cursor",
			},
		},
	},
}

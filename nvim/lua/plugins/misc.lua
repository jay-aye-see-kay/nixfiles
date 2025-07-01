return {
	{
		"hedyhli/outline.nvim",
		lazy = true,
		cmd = { "Outline", "OutlineOpen" },
		opts = {},
		keys = {
			{ "<leader>o", "<cmd>Outline!<cr>", desc = "toggle outline" },
		},
	},

	{
		"ggandor/leap.nvim",
		dependencies = {
			"tpope/vim-repeat",
		},
		config = function()
			require("leap").create_default_mappings()
		end,
	},

	{
		"windwp/nvim-ts-autotag",
		event = "VeryLazy",
		opts = {},
	},

	{
		"JoosepAlviste/nvim-ts-context-commentstring",
		init = function()
			vim.g.skip_ts_context_commentstring_module = true
		end,
	},

	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup({
				pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
			})
		end,
	},

	{
		"kylechui/nvim-surround",
		version = "^3.0.0", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
		config = function() end,
	},

	{
		"lewis6991/hover.nvim",
		lazy = true,
		config = function()
			require("hover").setup({
				init = function()
					require("hover.providers.lsp")
					require("hover.providers.gh")
					require("hover.providers.gh_user")
					require("hover.providers.jira")
					require("hover.providers.man")
					require("hover.providers.dictionary")
				end,
				preview_opts = {
					border = nil,
				},
				-- Whether the contents of a currently open hover window should be moved
				-- to a :h preview-window when pressing the hover keymap.
				preview_window = true,
				title = true,
			})
		end,
		keys = {
			{
				"gK",
				function()
					require("hover").hover_select()
				end,
				desc = "hover.nvim (select)",
			},
		},
	},

	{
		"mbbill/undotree",
		lazy = true,
		keys = {
			{ "\\u", "<cmd>UndotreeToggle<cr>", desc = "Toggle undotree" },
		},
	},

	{
		"johmsalas/text-case.nvim",
		config = function()
			local textcase = require("textcase")
			textcase.setup({ prefix = "ga" })
			textcase.register_keybindings("ga", textcase.api.to_dash_case, {
				prefix = "ga",
				quick_replace = "k",
				operator = "ok",
				lsp_rename = "K",
			})
			require("telescope").load_extension("textcase")
		end,
		keys = {
			"ga",
			{ "ga.", "<cmd>TextCaseOpenTelescope<CR>", mode = { "n", "x" }, desc = "Telescope" },
		},
		cmd = {
			"Subs",
			"TextCaseOpenTelescope",
			"TextCaseOpenTelescopeQuickChange",
			"TextCaseOpenTelescopeLSPChange",
			"TextCaseStartReplacingCommand",
		},
	},

	{
		"emmanueltouzery/decisive.nvim",
		lazy = true,
		ft = { "csv" },
		keys = {
			{ "\\v", ":lua require('decisive').align_csv({})<cr>", desc = "Align CSV" },
		},
	},
}

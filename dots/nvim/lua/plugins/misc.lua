-- Miscellaneous plugins
return {
	-- vim-unimpaired for bracket mappings (replaces mini.move and mini.bracketed)
	{
		"tpope/vim-unimpaired",
		event = "VeryLazy",
	},

	-- Outline sidebar
	{
		"hedyhli/outline.nvim",
		lazy = true,
		cmd = { "Outline", "OutlineOpen" },
		opts = {},
		keys = {
			{ "<leader>o", "<cmd>Outline!<cr>", desc = "toggle outline" },
		},
	},

	-- Auto-close and rename HTML/JSX tags
	{
		"windwp/nvim-ts-autotag",
		event = "VeryLazy",
		opts = {},
	},

	-- Context-aware commenting
	{
		"JoosepAlviste/nvim-ts-context-commentstring",
		init = function()
			vim.g.skip_ts_context_commentstring_module = true
		end,
		main = "ts_context_commentstring",
		opts = {
			-- We only use this via Comment.nvim's pre_hook, so the CursorHold
			-- autocmd is unnecessary. It also crashes on parser-less buffers
			-- (e.g. fugitive) since newer Neovim's get_parser returns nil
			-- instead of erroring, breaking the plugin's is_treesitter_active.
			enable_autocmd = false,
		},
	},
	{
		"numToStr/Comment.nvim",
		dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
		config = function()
			require("Comment").setup({
				pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
			})
		end,
	},

	-- Surround text objects
	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		opts = {},
	},

	-- Undo tree visualizer
	{
		"mbbill/undotree",
		lazy = true,
		keys = {
			{ "\\u", "<cmd>UndotreeToggle<cr>", desc = "Toggle undotree" },
		},
	},

	-- Text case conversion
	{
		"johmsalas/text-case.nvim",
		dependencies = { "nvim-telescope/telescope.nvim" },
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

	-- CSV alignment
	{
		"emmanueltouzery/decisive.nvim",
		lazy = true,
		ft = { "csv" },
		keys = {
			{ "\\v", ":lua require('decisive').align_csv({})<cr>", desc = "Align CSV" },
		},
	},

	{
		"samjwill/nvim-unception",
		init = function()
			-- Don't enable host-edit blocking in headless mode: unception errors
			-- out ("Must have exactly 1 argument") when $NVIM is inherited by a
			-- nested headless run (e.g. `nvim --headless +Lazy!` from :terminal).
			vim.g.unception_block_while_host_edits = #vim.api.nvim_list_uis() > 0
		end,
	},
}

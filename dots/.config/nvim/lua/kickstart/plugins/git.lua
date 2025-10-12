return {
	{
		"tpope/vim-fugitive",
		lazy = false,
		keys = { "<tab>", "=", ft = "fugitive", remap = true },
		config = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "gitcommit",
				callback = function()
					vim.opt_local.spell = true
				end,
			})
		end,
	},

	{
		"sindrets/diffview.nvim",
		lazy = true,
		cmd = {
			"DiffviewClose",
			"DiffviewFileHistory",
			"DiffviewFocusFiles",
			"DiffviewLog",
			"DiffviewOpen",
			"DiffviewRefresh",
			"DiffviewToggleFiles",
		},
		keys = {
			{ "<leader>gd", "<cmd>DiffviewFileHistory %<cr>", desc = "diffview current file" },
		},
	},

	{
		"lewis6991/gitsigns.nvim",
		lazy = true,
		event = "VeryLazy",
		opts = {
			current_line_blame_opts = { delay = 0 },
		},
		keys = {
			{ "<leader>hs", "<cmd>Gitsigns stage_hunk<cr>", mode = { "n", "v" }, desc = "stage hunk" },
			{ "<leader>hr", "<cmd>Gitsigns reset_hunk<cr>", mode = { "n", "v" }, desc = "reset hunk" },
			{ "<leader>hu", "<cmd>Gitsigns undo_stage_hunk<cr>", desc = "undo stage hunk" },
			{ "<leader>hp", "<cmd>Gitsigns preview_hunk<cr>", desc = "preview hunk" },
			{ "\\b", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "toggle current line blame" },
			{ "]h", "<cmd>Gitsigns next_hunk<cr>", desc = "next hunk" },
			{ "[h", "<cmd>Gitsigns prev_hunk<cr>", desc = "prev hunk" },
			-- setup hunk text objects
			{ "ih", "<cmd><C-U>Gitsigns select_hunk<cr>", mode = { "o", "x" }, desc = "a hunk" },
			{ "ah", "<cmd><C-U>Gitsigns select_hunk<cr>", mode = { "o", "x" }, desc = "a hunk" },
		},
	},
}

local helpers = require("config.helpers")

vim.api.nvim_create_autocmd("FileType", {
	pattern = "gitcommit",
	callback = function()
		vim.wo.spell = true
	end,
})

-- Git plugins
return {
	{
		"esmuellert/codediff.nvim",
		dependencies = { "MunifTanjim/nui.nvim" },
		cmd = "CodeDiff",
		keys = {
			{ "<leader>gs", "<cmd>CodeDiff<cr>", desc = "changes in working area" },
			{ "<leader>gd", "<cmd>CodeDiff history %<cr>", desc = "history of current file" },
		},
	},

	{
		"akinsho/git-conflict.nvim",
		event = "VeryLazy",
		keys = {
			{ "]x", "<Plug>(git-conflict-next-conflict)", desc = "next conflict marker" },
			{ "[x", "<Plug>(git-conflict-prev-conflict)", desc = "prev conflict marker" },
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

	{
		"tpope/vim-fugitive",
		dependencies = {
			"tpope/vim-rhubarb",
		},
		lazy = false,
		keys = {
			{ "<tab>", "=", ft = "fugitive", remap = true },
			{
				"<leader>gp",
				function()
					helpers.run_git_command_async("push -u")
				end,
				desc = "git push async",
			},
			{
				"<leader>gP",
				function()
					helpers.run_git_command_async("pull --rebase")
				end,
				desc = "git pull async",
			},
			{
				"<leader>gF",
				function()
					helpers.run_git_command_async("fetch")
				end,
				desc = "git fetch async",
			},
		},
	},
}

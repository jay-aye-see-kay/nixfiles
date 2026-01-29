-- Autocmd for gitcommit filetype
vim.api.nvim_create_autocmd("FileType", {
	pattern = "gitcommit",
	callback = function()
		vim.wo.spell = true
	end,
})

-- Git plugins
return {
	-- Diffview for viewing diffs
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

	-- Git conflict resolution
	{
		"akinsho/git-conflict.nvim",
		opts = {},
		keys = {
			{ "]x", "<Plug>(git-conflict-next-conflict)", desc = "next conflict marker" },
			{ "[x", "<Plug>(git-conflict-prev-conflict)", desc = "prev conflict marker" },
		},
	},

	-- Gitsigns for git decorations and hunks
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

	-- Vim fugitive for git commands
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
					local output = {}
					vim.fn.jobstart("git push", {
						on_stdout = function(_, data)
							if data then
								vim.list_extend(output, data)
							end
						end,
						on_stderr = function(_, data)
							if data then
								vim.list_extend(output, data)
							end
						end,
						on_exit = function(_, exit_code)
							vim.schedule(function()
								if exit_code == 0 then
									vim.notify("Git push succeeded", vim.log.levels.INFO)
									vim.fn["FugitiveDidChange"]() -- Refresh fugitive buffers
								else
									local error_msg = table.concat(output, "\n")
									vim.notify("Git push failed:\n" .. error_msg, vim.log.levels.ERROR)
								end
							end)
						end,
						stdout_buffered = true,
						stderr_buffered = true,
					})
					vim.notify("Pushing to remote...", vim.log.levels.INFO)
				end,
				desc = "git push async",
			},
		},
	},
}

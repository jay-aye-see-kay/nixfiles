local plugins = require("nln").plugins
local h = require("_cfg.helpers")

plugins["diffview.nvim"] = {
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
}

plugins["git-conflict.nvim"] = {
	opt = {},
	keys = {
		{ "]x", "<Plug>(git-conflict-next-conflict)", desc = "next conflict marker" },
		{ "[x", "<Plug>(git-conflict-prev-conflict)", desc = "prev conflict marker" },
	},
}

plugins["gitsigns.nvim"] = {
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
}

plugins["vim-fugitive"] = {
	event = "VeryLazy",
	keys = { "<tab>", "=", ft = "fugitive", remap = true },
}

h.autocmd("FileType", {
	pattern = "gitcommit",
	callback = function()
		vim.wo.spell = true
	end,
})

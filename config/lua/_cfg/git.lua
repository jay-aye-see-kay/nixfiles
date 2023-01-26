require("octo").setup()

require("which-key").register({
	p = {
		name = "+push",
		p = { "<cmd>G push<CR><ESC>", "push" },
		f = { "<cmd>G push<CR><ESC>", "push --force-with-lease" },
	},
	f = {
		name = "+fetch",
		f = { "<cmd>G fetch<CR><ESC>", "fetch" },
		p = { "<cmd>G pull<CR><ESC>", "pull" },
		r = { "<cmd>G pull --rebase<CR><ESC>", "pull and rebase" },
	},
}, { prefix = "<leader>g" })

-- vim.keymap.set("n", "<leader>gP", "<cmd>G push<CR><ESC>", { desc = "push" })
-- vim.keymap.set("n", "<leader>gff", "<cmd>G fetch<CR><ESC>", { desc = "fetch" })
-- vim.keymap.set("n", "<leader>gfp", "<cmd>G pull<CR><ESC>", { desc = "pull" })
-- vim.keymap.set("n", "<leader>gfr", "<cmd>G pull --rebase<CR><ESC>", { desc = "rebase" })

require("git-conflict").setup()
vim.keymap.set("n", "]c", "<Plug>(git-conflict-next-conflict)", { desc = "next conflict marker" })
vim.keymap.set("n", "[c", "<Plug>(git-conflict-prev-conflict)", { desc = "prev conflict marker" })

local gitsigns = require("gitsigns")
gitsigns.setup({
	current_line_blame_opts = { delay = 0 },
})

-- Navigation
vim.keymap.set("n", "]h", function()
	if vim.wo.diff then
		return "]h"
	end
	vim.schedule(gitsigns.next_hunk)
	return "<Ignore>"
end, { expr = true, desc = "next hunk" })
vim.keymap.set("n", "[h", function()
	if vim.wo.diff then
		return "[h"
	end
	vim.schedule(gitsigns.prev_hunk)
	return "<Ignore>"
end, { expr = true, desc = "prev hunk" })

-- Actions
vim.keymap.set({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", { desc = "stage hunk" })
vim.keymap.set({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", { desc = " reset hunk" })
vim.keymap.set("n", "<leader>hu", gitsigns.undo_stage_hunk, { desc = "undo stage hunk" })
vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, { desc = "preview hunk" })
vim.keymap.set("n", "<leader>hb", function()
	gitsigns.blame_line({ full = true })
end, { desc = "blame hunk" })
vim.keymap.set("n", "<leader>hd", gitsigns.diffthis, { desc = "diff this" })
vim.keymap.set("n", "<leader>gtb", gitsigns.toggle_current_line_blame, { desc = "toggle inline blame" })
vim.keymap.set("n", "<leader>gtd", gitsigns.toggle_deleted, { desc = "toggle showing deleted virtually" })

-- Text object
vim.keymap.set({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "a hunk" })
vim.keymap.set({ "o", "x" }, "ah", ":<C-U>Gitsigns select_hunk<CR>", { desc = "a hunk" })

vim.api.nvim_create_autocmd({ "FileType" }, {
	group = vim.api.nvim_create_augroup("FugitiveSetup", {}),
	pattern = "fugitive",
	callback = function()
		vim.keymap.set("n", "<tab>", "=", { buffer = 0, remap = true })
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("SpellcheckGitCommits", {}),
	pattern = "gitcommit",
	callback = function()
		vim.wo.spell = true
	end,
})

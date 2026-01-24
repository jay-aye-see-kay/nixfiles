local h = require("config.helpers")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.unception_block_while_host_edits = true

-- disable ex mode
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "gQ", "<nop>")

vim.keymap.set("i", "<c-a>", "<nop>") -- disable insert repeating
vim.opt.list = true
vim.opt.listchars = { tab = "»·", trail = "·", nbsp = "·" } -- Display extra whitespace
vim.opt.shada = "!,'1000,<50,s10,h" -- increase oldfile saved ( default is !,'100,<50,s10,h )

h.autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
	command = "setlocal cursorline",
})
h.autocmd({ "WinLeave" }, {
	callback = function()
		if vim.bo.filetype ~= "neo-tree" then
			vim.wo.cursorline = false
		end
	end,
})

-- prefer spaces over tabs
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

h.autocmd({ "TextYankPost" }, { command = "silent! lua vim.highlight.on_yank()" })

-- modern copy paste keymaps
vim.keymap.set("i", "<C-v>", "<C-r>+")
vim.keymap.set("v", "<C-c>", '"+y')

vim.opt.spellcapcheck = "" -- ignore capitalisation

vim.wo.relativenumber = true --Make line numbers default

vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 4

vim.opt.jumpoptions = "stack"

vim.filetype.add({
	filename = {
		["devbox.json"] = "jsonc",
	},
})

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.have_nerd_font = true
vim.g.unception_block_while_host_edits = true

-- From kickstart.nvim
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = "a"
vim.o.showmode = false -- it's already in the status line
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = "yes"
vim.o.updatetime = 250 -- decrease because it impacts CursorHold
vim.o.timeoutlen = 300 -- makes which-key nice
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.o.inccommand = "nosplit" -- preview substitutions as you type

-- Settings from mini.basics options.basic = true
vim.o.backup = false
vim.o.writebackup = false
vim.o.linebreak = true
vim.o.ruler = false
vim.o.wrap = false
vim.o.signcolumn = "yes"
vim.o.incsearch = true
vim.o.infercase = true
vim.o.smartindent = true
vim.o.completeopt = "menuone,noselect"
vim.o.splitkeep = "screen"
vim.o.confirm = true

-- disable ex mode
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "gQ", "<nop>")

vim.keymap.set("i", "<c-a>", "<nop>") -- disable insert repeating
vim.opt.list = true
vim.opt.listchars = { tab = "»·", trail = "·", nbsp = "·" } -- Display extra whitespace
vim.opt.shada = "!,'1000,<50,s10,h" -- increase oldfile saved ( default is !,'100,<50,s10,h )

-- Window navigation (from mini.basics)
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to window below" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to window above" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Move by visible lines (from mini.basics)
-- j/k move by display lines unless count is provided
vim.keymap.set({ "n", "x" }, "j", [[v:count == 0 ? 'gj' : 'j']], { expr = true, desc = "Move down" })
vim.keymap.set({ "n", "x" }, "k", [[v:count == 0 ? 'gk' : 'k']], { expr = true, desc = "Move up" })

-- Add empty lines (from mini.basics, but using unimpaired style)
vim.keymap.set(
	"n",
	"] ",
	"<Cmd>call append(line('.'),     repeat([''], v:count1))<CR>",
	{ desc = "Put empty line below" }
)
vim.keymap.set(
	"n",
	"[ ",
	"<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>",
	{ desc = "Put empty line above" }
)

-- Save file (from mini.basics)
vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- System clipboard operations (from mini.basics)
vim.keymap.set({ "n", "x" }, "gy", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set("n", "gp", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("x", "gp", '"+P', { desc = "Paste from system clipboard" })

-- Toggle options (some from mini.basics)
vim.keymap.set(
	"n",
	"\\d",
	"<cmd>lua vim.diagnostic.enable(not vim.diagnostic.is_enabled())<cr>",
	{ desc = "Toggle diagnostic" }
)
vim.keymap.set("n", "\\h", "<cmd>set hlsearch!<cr>", { desc = "Toggle search highlight" })
vim.keymap.set("n", "\\i", "<cmd>set ignorecase!<cr>", { desc = "Toggle ignorecase" })
vim.keymap.set("n", "\\s", "<cmd>setlocal spell!<cr>", { desc = "Toggle spell" })
vim.keymap.set("n", "\\w", "<cmd>setlocal wrap!<cr>", { desc = "Toggle wrap" })

-- Buffer deletion (replacing mini.bufremove)
vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Cursorline only in active window
vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
	command = "setlocal cursorline",
})
vim.api.nvim_create_autocmd({ "WinLeave" }, {
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

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- modern copy paste keymaps
vim.keymap.set("i", "<C-v>", "<C-r>+")
vim.keymap.set("v", "<C-c>", '"+y')

vim.opt.spellcapcheck = "" -- ignore capitalisation
vim.wo.relativenumber = true -- Make line numbers relative

vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 4

vim.filetype.add({
	filename = {
		["devbox.json"] = "jsonc",
	},
})

vim.keymap.set("n", ",v", "<cmd>e ~/nixfiles/dots/.config/nvim/TODO.md<cr>", {
	desc = "open nvim todo file",
})

vim.keymap.set("n", ",i", "<cmd>e ~/obsidian/notes/ideas.md<cr>", {
	desc = "open ideas file",
})

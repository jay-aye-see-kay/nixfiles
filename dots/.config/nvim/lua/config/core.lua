vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.unception_block_while_host_edits = true

-- Settings from mini.basics options.basic = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.mouse = 'a'
vim.opt.breakindent = true
vim.opt.linebreak = true
vim.opt.number = true
vim.opt.ruler = false
vim.opt.showmode = false
vim.opt.wrap = false
vim.opt.signcolumn = 'yes'
vim.opt.fillchars = 'eob: '
vim.opt.incsearch = true
vim.opt.infercase = true
vim.opt.smartindent = true
vim.opt.completeopt = 'menuone,noselect'
vim.opt.virtualedit = 'block'
vim.opt.formatoptions = 'qjl1'
vim.opt.shortmess:append('WcC')
vim.opt.splitkeep = 'screen'

-- disable ex mode
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "gQ", "<nop>")

vim.keymap.set("i", "<c-a>", "<nop>") -- disable insert repeating
vim.opt.list = true
vim.opt.listchars = { tab = "»·", trail = "·", nbsp = "·" } -- Display extra whitespace
vim.opt.shada = "!,'1000,<50,s10,h" -- increase oldfile saved ( default is !,'100,<50,s10,h )

-- Window navigation (from mini.basics)
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to window below' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to window above' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

-- Move by visible lines (from mini.basics)
-- j/k move by display lines unless count is provided
vim.keymap.set({ 'n', 'x' }, 'j', [[v:count == 0 ? 'gj' : 'j']], { expr = true, desc = 'Move down' })
vim.keymap.set({ 'n', 'x' }, 'k', [[v:count == 0 ? 'gk' : 'k']], { expr = true, desc = 'Move up' })

-- Add empty lines (from mini.basics, but using unimpaired style)
vim.keymap.set("n", "] ", "<Cmd>call append(line('.'),     repeat([''], v:count1))<CR>", { desc = "Put empty line below" })
vim.keymap.set("n", "[ ", "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>", { desc = "Put empty line above" })

-- Save file (from mini.basics)
vim.keymap.set({ 'n', 'i', 'v' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save file' })

-- System clipboard operations (from mini.basics)
vim.keymap.set({ 'n', 'x' }, 'gy', '"+y', { desc = 'Copy to system clipboard' })
vim.keymap.set('n', 'gp', '"+p', { desc = 'Paste from system clipboard' })
vim.keymap.set('x', 'gp', '"+P', { desc = 'Paste from system clipboard' })

-- Toggle options (some from mini.basics)
vim.keymap.set('n', '\\d', '<cmd>lua vim.diagnostic.enable(not vim.diagnostic.is_enabled())<cr>', { desc = "Toggle diagnostic" })
vim.keymap.set('n', '\\h', '<cmd>set hlsearch!<cr>', { desc = "Toggle search highlight" })
vim.keymap.set('n', '\\i', '<cmd>set ignorecase!<cr>', { desc = "Toggle ignorecase" })
vim.keymap.set('n', '\\s', '<cmd>setlocal spell!<cr>', { desc = "Toggle spell" })
vim.keymap.set('n', '\\w', '<cmd>setlocal wrap!<cr>', { desc = "Toggle wrap" })

-- Buffer deletion (replacing mini.bufremove)
vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

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

vim.api.nvim_create_autocmd({ "TextYankPost" }, { command = "silent! lua vim.highlight.on_yank()" })

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

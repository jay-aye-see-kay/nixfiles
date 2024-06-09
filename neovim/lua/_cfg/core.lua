local h = require("_cfg.helpers")
vim.g.unception_block_while_host_edits = true

-- basic core stuff {{{
-- disable ex mode
h.map("n", "Q", "<nop>")
h.map("n", "gQ", "<nop>")

h.map("i", "<c-a>", "<nop>") -- disable insert repeating
vim.cmd([[ set list listchars=tab:»·,trail:·,nbsp:· ]]) -- Display extra whitespace
vim.cmd([[ set shada=!,'1000,<50,s10,h ]]) -- increase oldfile saved ( default is !,'100,<50,s10,h )

h.autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
	command = "setlocal cursorline",
})
h.autocmd({ "WinLeave" }, {
	callback = function()
		if vim.bo.filetype ~= "neo-tree" then
			vim.cmd("setlocal nocursorline")
		end
	end,
})

-- prefer spaces over tabs
vim.cmd([[ set tabstop=2 ]])
vim.cmd([[ set softtabstop=2 ]])
vim.cmd([[ set shiftwidth=2 ]])
vim.cmd([[ set expandtab ]])

h.autocmd({ "TextYankPost" }, { command = "silent! lua vim.highlight.on_yank()" })

-- modern copy paste keymaps
h.map("i", "<C-v>", "<C-r>+")
h.map("v", "<C-c>", '"+y')

-- spelling
vim.opt.spellcapcheck = nil -- ignore capitalisation

vim.wo.relativenumber = true --Make line numbers default

vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 4

vim.opt.jumpoptions = "stack"
-- }}}

-- extend color scheme
h.autocmd({ "ColorScheme" }, {
	callback = function()
		local copy_color = function(from, to)
			vim.api.nvim_set_hl(0, to, vim.api.nvim_get_hl_by_name(from, true))
		end
		copy_color("DiffAdd", "diffAdded")
		copy_color("DiffDelete", "diffRemoved")
		copy_color("DiffChange", "diffChanged")
	end,
})

vim.o.background = "dark"
require("catppuccin").setup({
	term_colors = true,
	integrations = {
		cmp = true,
		gitsigns = true,
		markdown = true,
		mini = true,
		neotree = true,
		noice = true,
		notify = true,
		semantic_tokens = true,
		telescope = true,
		which_key = true,
		-- For more integrations https://github.com/catppuccin/nvim#integrations
	},
	custom_highlights = function(colors)
		return {
			CodeBlockBackground = { bg = colors.surface0 },
			ActiveTerm = { bg = colors.crust },
		}
	end,
})
vim.cmd.colorscheme("catppuccin-macchiato") -- latte, frappe, macchiato, mocha

-- {{{ misc and UI stuff
h.map("n", "<leader>u", "<cmd>MundoToggle<cr>")
vim.g.mundo_preview_bottom = 1
vim.g.mundo_width = 40
vim.g.mundo_preview_height = 20
-- }}}

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

-- Setup keymaps
vim.keymap.set("n", "K", require("hover").hover, { desc = "hover.nvim" })
vim.keymap.set("n", "gK", require("hover").hover_select, { desc = "hover.nvim (select)" })

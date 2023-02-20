local h = require("_cfg.helpers")

-- basic core stuff {{{

-- faster window movements
h.map("n", "<c-h>", "<c-w>h")
h.map("n", "<c-j>", "<c-w>j")
h.map("n", "<c-k>", "<c-w>k")
h.map("n", "<c-l>", "<c-w>l")

-- disable ex mode
h.map("n", "Q", "<nop>")
h.map("n", "gQ", "<nop>")

h.map("i", "<c-a>", "<nop>") -- disable insert repeating
h.map("n", "Y", "y$") -- make Y behave like C and D

vim.cmd([[ set splitbelow splitright ]]) -- matches i3 behaviour
vim.cmd([[ set linebreak ]]) -- don't break words when wrapping
vim.cmd([[ set list listchars=tab:»·,trail:·,nbsp:· ]]) -- Display extra whitespace
vim.cmd([[ set nojoinspaces ]]) -- Use one space, not two, after punctuation.

vim.cmd([[ set undofile ]])

-- increase oldfile saved ( default is !,'100,<50,s10,h )
vim.cmd([[ set shada=!,'1000,<50,s10,h ]])

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

vim.g.unception_block_while_host_edits = true

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

-- stuff from https://github.com/mjlbach/defaults.nvim

-- remap space as leader key
h.map("", "<Space>", "")
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.o.inccommand = "nosplit" --Incremental live completion
vim.wo.number = true --Make line numbers default
vim.wo.relativenumber = true --Make line numbers default
vim.o.hidden = true --Do not save when switching buffers
vim.o.mouse = "a" --Enable mouse mode
vim.o.breakindent = true --Enable break indent
vim.wo.signcolumn = "yes"

-- set highlight on search
vim.o.hlsearch = false
vim.o.incsearch = true

-- case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- search within selection from visual mode
vim.keymap.set("x", "/", "<Esc>/\\%V")

vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 4
vim.opt.wrap = false

h.autocmd({ "FileType" }, {
	pattern = "fzf",
	command = "tnoremap <buffer> <ESC> <ESC>",
})
-- }}}

-- visuals look nice {{{
vim.keymap.set("n", "<leader>yd", function()
	if vim.o.background == "dark" then
		vim.o.background = "light"
	else
		vim.o.background = "dark"
	end
end, { desc = "toggle brightness" })

-- extend color scheme
h.autocmd({ "ColorScheme" }, {
	callback = function()
		local function copy_color(from, to)
			vim.api.nvim_set_hl(0, to, vim.api.nvim_get_hl_by_name(from, true))
		end
		copy_color("DiffAdd", "diffAdded")
		copy_color("DiffDelete", "diffRemoved")
		copy_color("DiffChange", "diffChanged")
	end,
})

vim.api.nvim_set_var("vim_json_syntax_conceal", 0)
vim.o.termguicolors = true
vim.o.background = "light"
vim.g.zenbones = {
	darken_noncurrent_window = true,
	lighten_noncurrent_window = true,
}
vim.cmd.colorscheme("zenbones")

local navic = require("nvim-navic")

-- modify the theme so sections don't change color with mode
local lualine_theme = vim.deepcopy(require("lualine.utils.loader").load_theme("zenbones"))
lualine_theme.insert = nil
lualine_theme.replace = nil
lualine_theme.visual = nil
lualine_theme.command = nil

require("lualine").setup({
	options = {
		theme = lualine_theme,
		globalstatus = true,
		disabled_filetypes = {
			winbar = { "", "neo-tree", "Outline", "fugitive" },
		},
	},
	sections = {
		lualine_a = { "vim.fs.basename(vim.fn.getcwd())" },
		lualine_b = { "branch", "diff" },
		lualine_c = { "diagnostics" },
		lualine_x = { "lsp_progress", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	winbar = {
		lualine_b = { { "filename", path = 1 } },
		lualine_c = { { navic.get_location, cond = navic.is_available } },
	},
	inactive_winbar = {
		lualine_b = { { "filename", path = 1 } },
	},
	tabline = {
		lualine_a = {
			{
				"tabs",
				mode = 1,
				max_length = vim.o.columns,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				fmt = function(_, context)
					local winnr = vim.fn.tabpagewinnr(context.tabnr)
					local tabcwd = vim.fs.basename(vim.fn.getcwd(winnr, context.tabnr))
					return "[" .. context.tabnr .. ": " .. tabcwd .. "]"
				end,
			},
		},
	},
})
vim.o.showtabline = 1

require("indent_blankline").setup({
	enabled = false,
	show_current_context = true,
})
vim.keymap.set("n", "<leader>yb", "<cmd>IndentBlanklineToggle!<cr>")

require("symbols-outline").setup({
	width = 40,
	relative_width = false,
})
-- }}}

-- {{{ misc and UI stuff
require("nvim-surround").setup()

h.map("n", "<leader>u", "<cmd>MundoToggle<cr>")
vim.g.mundo_preview_bottom = 1
vim.g.mundo_width = 40
vim.g.mundo_preview_height = 20

require("various-textobjs").setup({ useDefaultKeymaps = true })
-- }}}

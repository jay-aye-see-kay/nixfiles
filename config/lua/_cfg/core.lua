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
-- }}}

-- visuals look nice {{{

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

vim.api.nvim_set_var("vim_json_syntax_conceal", 0)

require("headlines").setup({
	markdown = {
		fat_headlines = false,
		headline_highlights = {
			"Headline1",
			"Headline2",
			"Headline3",
			"Headline4",
			"Headline5",
			"Headline6",
		},
		codeblock_highlight = "CodeBlock",
		dash_highlight = "Dash",
		quote_highlight = "Quote",
	},
})

vim.o.background = "dark"
require("catppuccin").setup({
	flavour = "mocha", -- latte, frappe, macchiato, mocha
	show_end_of_buffer = true,
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
})
vim.cmd.colorscheme("catppuccin")

-- modify the theme so sections don't change color with mode
local lualine_theme = vim.deepcopy(require("lualine.utils.loader").load_theme("catppuccin"))
lualine_theme.insert = nil
lualine_theme.replace = nil
lualine_theme.visual = nil
lualine_theme.command = nil

require("lualine").setup({
	options = {
		theme = lualine_theme,
		globalstatus = true,
	},
	sections = {
		lualine_a = { "vim.fs.basename(vim.fn.getcwd())" },
		lualine_b = { { "filename", path = 1 } },
		lualine_c = { "diagnostics" },
		lualine_x = { "lsp_progress", "filetype" },
		lualine_y = { "branch" },
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
-- }}}

-- {{{ misc and UI stuff
h.map("n", "<leader>u", "<cmd>MundoToggle<cr>")
vim.g.mundo_preview_bottom = 1
vim.g.mundo_width = 40
vim.g.mundo_preview_height = 20
-- }}}

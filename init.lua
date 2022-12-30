-- helpers {{{
M = {}

function M.merge(t1, t2)
	return vim.tbl_extend("force", t1, t2)
end

function M.make_directed_maps(command_desc, command)
	local directions = {
		left = { key = "h", description = "to left", command_prefix = "aboveleft vsplit" },
		right = { key = "l", description = "to right", command_prefix = "belowright vsplit" },
		above = { key = "k", description = "above", command_prefix = "aboveleft split" },
		below = { key = "j", description = "below", command_prefix = "belowright split" },
		in_place = { key = ".", description = "in place", command_prefix = nil },
		tab = { key = ",", description = "in new tab", command_prefix = "tabnew" },
	}

	local maps = {}
	for _, d in pairs(directions) do
		local full_description = command_desc .. " " .. d.description
		local full_command = d.command_prefix -- approximating a ternary
				and "<CMD>" .. d.command_prefix .. " | " .. command .. "<CR>"
			or "<CMD>" .. command .. "<CR>"

		maps[d.key] = { full_command, full_description }
	end
	return maps
end

function M.exec(command)
	local file, err = io.popen(command, "r")
	if file == nil then
		print("file could not be opened:", err)
		return
	end
	local res = {}
	for line in file:lines() do
		table.insert(res, line)
	end
	return res
end

function M.map(mode, lhs, rhs, extraOpts)
	local opts = { noremap = true, silent = true }
	if extraOpts then
		opts = M.merge(opts, extraOpts)
	end
	vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
end

function M.buf_map(buffer, mode, lhs, rhs, extraOpts)
	local opts = { noremap = true, silent = true }
	if extraOpts then
		opts = M.merge(opts, extraOpts)
	end
	vim.api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
end

-- }}}

-- init file setup {{{
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = vim.api.nvim_create_augroup("InitFilesSetup", {}),
	pattern = { "*code/neovim-flake/*.lua" },
	command = "Neoformat stylua",
})
-- }}}

-- basic core stuff {{{

-- faster window movements
M.map("n", "<c-h>", "<c-w>h")
M.map("n", "<c-j>", "<c-w>j")
M.map("n", "<c-k>", "<c-w>k")
M.map("n", "<c-l>", "<c-w>l")

-- disable ex mode
M.map("n", "Q", "<nop>")
M.map("n", "gQ", "<nop>")

M.map("i", "<c-a>", "<nop>") -- disable insert repeating
M.map("n", "Y", "y$") -- make Y behave like C and D

vim.cmd([[ set splitbelow splitright ]]) -- matches i3 behaviour
vim.cmd([[ set linebreak ]]) -- don't break words when wrapping
vim.cmd([[ set list listchars=tab:»·,trail:·,nbsp:· ]]) -- Display extra whitespace
vim.cmd([[ set nojoinspaces ]]) -- Use one space, not two, after punctuation.

vim.cmd([[ set undofile ]])

-- increase oldfile saved ( default is !,'100,<50,s10,h )
vim.cmd([[ set shada=!,'1000,<50,s10,h ]])

local cursor_augroup = vim.api.nvim_create_augroup("CursorLineOnlyOnFocusedWindow", {})
vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
	group = cursor_augroup,
	command = "setlocal cursorline",
})
vim.api.nvim_create_autocmd({ "WinLeave" }, {
	group = cursor_augroup,
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

vim.api.nvim_create_autocmd({ "TextYankPost" }, {
	group = vim.api.nvim_create_augroup("HighlightOnYank", {}),
	command = "silent! lua vim.highlight.on_yank()",
})

-- modern copy paste keymaps
M.map("i", "<C-v>", "<C-r>+")
M.map("v", "<C-c>", '"+y')

-- stuff from https://github.com/mjlbach/defaults.nvim

-- remap space as leader key
M.map("", "<Space>", "")
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.o.inccommand = "nosplit" --Incremental live completion
vim.wo.number = true --Make line numbers default
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

vim.api.nvim_create_autocmd({ "FileType" }, {
	group = vim.api.nvim_create_augroup("FzfEscapeBehavior", {}),
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
vim.api.nvim_create_autocmd({ "ColorScheme" }, {
	group = vim.api.nvim_create_augroup("ExtendColorScheme", {}),
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
require("lualine").setup({
	options = {
		theme = "zenbones",
		globalstatus = true,
		disabled_filetypes = {
			winbar = { "", "neo-tree", "Outline", "fugitive" },
		},
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff" },
		lualine_c = { "diagnostics" },
		lualine_x = { "lsp_progress", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	winbar = {
		lualine_a = { "vim.fs.basename(vim.fn.getcwd())" },
		lualine_b = { { "filename", path = 1 } },
		lualine_c = { { navic.get_location, cond = navic.is_available } },
	},
	inactive_winbar = {
		lualine_b = { { "filename", path = 1 } },
	},
})

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

-- lsp {{{
local lsp_servers = {
	"bashls",
	"cssls",
	"dockerls",
	"gopls",
	"html",
	"jsonls",
	"pyright",
	"rnix",
	"rust_analyzer",
	"solargraph",
	"sumneko_lua",
	"tsserver",
	"vimls",
	"yamlls",
}

for _, lsp in pairs(lsp_servers) do
	local settings = {}
	if lsp == "jsonls" then
		settings.json = {
			schemas = require("schemastore").json.schemas(),
		}
	elseif lsp == "sumneko_lua" then
		settings.Lua = {
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim" } },
			workspace = { checkThirdParty = false },
			telemetry = { enable = false },
		}
	end

	require("lspconfig")[lsp].setup({
		settings = settings,
		on_attach = function(client, bufnr)
			if lsp == "tsserver" then
				local ts_utils = require("nvim-lsp-ts-utils")
				ts_utils.setup({})
				ts_utils.setup_client(client)
			end
			if client.server_capabilities.documentSymbolProvider then
				require("nvim-navic").attach(client, bufnr)
			end
		end,
	})
end

vim.keymap.set("n", "gd", require("telescope.builtin").lsp_definitions, { desc = "Goto/find definitions" })
vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, { desc = "Find references" })
vim.keymap.set("n", "gy", require("telescope.builtin").lsp_type_definitions, { desc = "Find type definitions" })
vim.keymap.set("n", "gh", vim.lsp.buf.hover, { desc = "Hover docs" })
vim.keymap.set("n", "gI", vim.lsp.buf.implementation, { desc = "Goto implementation" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("i", "<C-i>", function()
	require("cmp").mapping.close()()
	vim.lsp.buf.signature_help()
end, { desc = "Signature Documentation" })

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
	border = "single",
})

function QuietLsp()
	vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
		signs = false,
		underline = false,
		virtual_text = false,
	})
end

function LoudenLsp()
	vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
		signs = true,
		underline = true,
		virtual_text = true,
	})
end

function DisableAutocomplete()
	require("cmp").setup.buffer({
		completion = { autocomplete = false },
	})
end

function EnableAutocomplete()
	require("cmp").setup.buffer({})
end

require("lsp_lines").setup()
vim.diagnostic.config({ virtual_lines = false })

vim.keymap.set("n", "<leader>lm", function()
	vim.diagnostic.config({ virtual_text = false, virtual_lines = true })
end, { desc = "Enable multiline diagnotics" })

vim.keymap.set("n", "<leader>lM", function()
	vim.diagnostic.config({ virtual_text = true, virtual_lines = false })
end, { desc = "Disable multiline diagnotics" })

-- }}}

-- completions {{{
vim.cmd([[ set completeopt=menu,menuone,noselect ]])

require("nvim-autopairs").setup()

local cmp = require("cmp")
local cmp_autopairs = require("nvim-autopairs.completion.cmp")

cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

cmp.setup({
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-y>"] = cmp.mapping.confirm({ select = true }),
		["<C-k>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
		["<C-e>"] = cmp.mapping({
			i = cmp.mapping.abort(),
			c = cmp.mapping.close(),
		}),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
		{ name = "nvim_lua" },
	}, {
		{ name = "path" },
		{
			name = "buffer",
			options = {
				get_bufnrs = function()
					return vim.api.nvim_list_bufs()
				end,
			},
		},
	}),
	formatting = {
		format = require("lspkind").cmp_format(),
	},
})
-- }}}

-- notes/wiki {{{
require("mkdnflow").setup({
	modules = {
		bib = false,
		folds = false,
	},
	to_do = {
		symbols = { " ", "-", "x" },
		update_parents = false,
		not_started = " ",
		in_progress = "-",
		complete = "x",
	},
	mappings = {
		MkdnGoBack = false,
		MkdnGoForward = false,
	},
	perspective = {
		-- Changes in perspective will be reflected in the nvim working directory.
		-- (In other words, the working directory will "heel" to the plugin's perspective.)
		-- This helps ensure (at least) that path completions (if using a completion plugin with support for paths) will be accurate and usable.
		-- Leaving this note as I don't know if I want this behaviour
		nvim_wd_heel = true,
	},
})

vim.api.nvim_create_autocmd({ "FileType" }, {
	group = vim.api.nvim_create_augroup("MarkdownTsFolding", {}),
	pattern = { "markdown", "md" },
	callback = function()
		vim.opt_local.foldlevel = 99
		vim.opt_local.foldmethod = "expr"
		vim.opt_local.foldexpr = "nvim_treesitter#foldexpr()"
	end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
	group = vim.api.nvim_create_augroup("TextWrappingAndMovements", {}),
	pattern = { "text", "markdown", "md" },
	callback = function()
		vim.opt_local.wrap = true
		M.buf_map(0, "n", "j", "gj")
		M.buf_map(0, "n", "k", "gk")
	end,
})

local function open_logbook(days_from_today)
	local date_offset = (days_from_today or 0) * 24 * 60 * 60
	local filename = os.date("%Y-%m-%d-%A", os.time() + date_offset) .. ".md"
	local todays_journal_file = "~/Documents/notes/logbook/" .. filename
	vim.cmd("edit " .. todays_journal_file)
end

function LogbookToday()
	open_logbook()
end

function LogbookYesterday()
	open_logbook(-1)
end

function LogbookTomorrow()
	open_logbook(1)
end

vim.cmd([[command! LogbookToday :call v:lua.LogbookToday()]])
vim.cmd([[command! LogbookYesterday :call v:lua.LogbookYesterday()]])
vim.cmd([[command! LogbookTomorrow :call v:lua.LogbookTomorrow()]])
-- }}}

-- file tree {{{
vim.g.neo_tree_remove_legacy_commands = 1

require("neo-tree").setup({
	window = {
		position = "left",
		width = 30,
		mappings = {
			["<space>"] = false,
			["l"] = "open",
			["h"] = "close_node",
		},
	},
	filesystem = {
		filtered_items = {
			visible = true,
			hide_dotfiles = false,
		},
		hijack_netrw_behavior = "open_current",
		use_libuv_file_watcher = true,
		follow_current_file = true,
		window = {
			mappings = {
				["H"] = "navigate_up",
				["L"] = "set_root",
				["."] = "toggle_hidden",
				["/"] = "fuzzy_finder",
				["D"] = "fuzzy_finder_directory",
				["<c-x>"] = "clear_filter",
				["[g"] = "prev_git_modified",
				["]g"] = "next_git_modified",
			},
		},
	},
})

require("window-picker").setup()

-- window jumper/picker, used by neotree, but might be cool on it's own?
vim.keymap.set("n", "<leader>j", function()
	local picked_window_id = require("window-picker").pick_window()
	if picked_window_id then
		vim.api.nvim_set_current_win(picked_window_id)
	end
end, { desc = "Pick a window" })
-- }}}

-- keymaps {{{
M.map("n", "<c-s>", "<cmd>w<cr>")

local directed_keymaps = {
	git_status = M.make_directed_maps("Git Status", "Gedit :"),
	new_terminal = M.make_directed_maps("New terminal", "terminal"),
	todays_notepad = M.make_directed_maps("Today's notepad", "LogbookToday"),
	yesterdays_notepad = M.make_directed_maps("Yesterday's notepad", "LogbookYesterday"),
	tomorrows_notepad = M.make_directed_maps("Tomorrow's notepad", "LogbookTomorrow"),
	file_explorer = M.make_directed_maps("File explorer", "Neotree reveal current"),
}

--- grep through old markdown notes
local grep_notes = function()
	require("telescope.builtin").live_grep({ cwd = "$HOME/Documents/notes" })
end

--- git files, falling back onto all files in cwd if not in a git repo
local function project_files()
	local ok = pcall(require("telescope.builtin").git_files)
	if not ok then
		require("telescope.builtin").find_files()
	end
end

local telescope_fns = require("telescope.builtin")

local main_keymap = {
	lsp = {
		name = "+lsp",
		s = { "<cmd>SymbolsOutline<cr>", "Symbols outline" },
		a = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code action" },
		r = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename symbol" },
		d = { "<cmd>Telescope lsp_document_diagnostics<cr>", "Show document diagnostics" },
		D = { "<cmd>Telescope lsp_workspace_diagnostics<cr>", "Show workspace diagnostics" },
		t = { "<cmd>TroubleToggle<cr>", "Show workspace diagnostics" },
		i = { "<cmd>LspInfo<cr>", "Info" },
		f = { "<cmd>lua vim.lsp.buf.format()<cr>", "Format buffer with LSP" },

		-- hack: pop into insert mode after to trigger lsp applying settings
		q = { "<cmd>call v:lua.QuietLsp()<cr>i <bs><esc>", "Hide lsp diagnostics" },
		Q = { "<cmd>call v:lua.LoudenLsp()<cr>i <bs><esc>", "Show lsp diagnostics" },

		n = { "<cmd>call v:lua.DisableAutocomplete()<cr>", "Disable autocomplete" },
		N = { "<cmd>call v:lua.EnableAutocomplete()<cr>", "Enable autocomplete" },
	},
	finder = {
		name = "+find",
		b = {
			function()
				require("telescope.builtin").buffers({ sort_mru = true, ignore_current_buffer = true })
			end,
			"🔭 buffers (cwd only)",
		},
		B = {
			function()
				require("telescope.builtin").buffers({ sort_mru = true, ignore_current_buffer = true, cwd_only = true })
			end,
			"🔭 buffers (cwd only)",
		},
		f = { telescope_fns.find_files, "🔭 files" },
		g = { project_files, "🔭 git files" },
		h = {
			function()
				require("telescope.builtin").help_tags({ default_text = vim.fn.expand("<cword>") })
			end,
			"🔭 help tags",
		},
		c = { telescope_fns.commands, "🔭 commands" },
		o = { telescope_fns.oldfiles, "🔭 oldfiles" },
		l = { telescope_fns.current_buffer_fuzzy_find, "🔭 buffer lines" },
		w = { telescope_fns.spell_suggest, "🔭 spelling suggestions" },
		s = { telescope_fns.symbols, "🔭 unicode and emoji symbols" },
		a = { telescope_fns.live_grep, "🔭 full text search" },
		u = { telescope_fns.grep_string, "🔭 word under cursor" },
		n = { grep_notes, "🔭 search all notes" },
	},
	git = M.merge(directed_keymaps.git_status, {
		name = "+git",
		g = { "<Cmd>Telescope git_commits<CR>", "🔭 commits" },
		c = { "<Cmd>Telescope git_bcommits<CR>", "🔭 buffer commits" },
		b = { "<Cmd>Telescope git_branches<CR>", "🔭 branches" },
	}),
	terminal = M.merge(directed_keymaps.new_terminal, {
		name = "+terminal",
	}),
	explorer = M.merge(directed_keymaps.file_explorer, {
		name = "+file explorer",
		e = { "<cmd>Neotree toggle<cr>", "toggle side file tree" },
	}),
	notes = M.merge(directed_keymaps.todays_notepad, {
		name = "+notes",
		f = { grep_notes, "🔭 search all notes" },
		y = M.merge(directed_keymaps.yesterdays_notepad, {
			name = "+Yesterday' notepad",
		}),
		t = M.merge(directed_keymaps.tomorrows_notepad, {
			name = "+Tomorrow' notepad",
		}),
	}),
	misc = {
		name = "+misc",
		p = {
			function()
				vim.api.nvim_win_set_width(0, 60)
				vim.api.nvim_win_set_option(0, "winfixwidth", true)
			end,
			"pin window to edge",
		},
		P = {
			function()
				vim.api.nvim_win_set_option(0, "winfixwidth", false)
			end,
			"unpin window",
		},
	},
}

vim.opt.timeoutlen = 250

local which_key = require("which-key")
which_key.setup({
	plugins = {
		spelling = { enabled = true },
	},
	window = {
		winblend = 15,
	},
	layout = {
		spacing = 4,
		align = "center",
	},
})

which_key.register({
	e = main_keymap.explorer,
	f = main_keymap.finder,
	g = main_keymap.git,
	l = main_keymap.lsp,
	t = main_keymap.terminal,
	n = main_keymap.notes,
	m = main_keymap.misc,
}, {
	prefix = "<leader>",
})

which_key.register({
	name = "quick keymaps",
	b = main_keymap.finder.b, -- buffers
	B = main_keymap.finder.B, -- buffers (cwd only)
	g = main_keymap.finder.g, -- git_files
	f = main_keymap.finder.f, -- find_files
	o = main_keymap.finder.o, -- old_files
	a = main_keymap.finder.a, -- Rg
	["."] = main_keymap.explorer["."],
	[">"] = main_keymap.explorer.e["."],
}, {
	prefix = ",",
})
-- }}}

-- snippets {{{
require("luasnip.loaders.from_vscode").lazy_load()

-- these need to work in insert and select mode for some reason
local function snip_map(lhs, rhs)
	M.map("i", lhs, rhs)
	M.map("s", lhs, rhs)
end

snip_map("<C-j>", "<Plug>luasnip-expand-snippet")
snip_map("<C-l>", "<Plug>luasnip-jump-next")
snip_map("<C-h>", "<Plug>luasnip-jump-prev")

local ls = require("luasnip")
local l = require("luasnip.extras").lambda
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node
local vsc = ls.parser.parse_snippet

local js_snippets = {
	-- React.useState()
	s("us", {
		t("const ["),
		i(1, "foo"),
		t(", set"),
		l(l._1:gsub("^%l", string.upper), 1),
		t("] = useState("),
		i(2),
		t(")"),
	}),
	-- React.useEffect()
	vsc("ue", "useEffect(() => {\n\t${1}\n}, [${0}])", {}),
	-- basics + keywords
	vsc("c", "const ${1} = ${0}", {}),
	vsc("l", "let ${1} = ${0}", {}),
	vsc("e", "export ${0}", {}),
	vsc("aw", "await ${0}", {}),
	vsc("as", "async ${0}", {}),
	vsc("d", "debugger", {}),
	-- function
	vsc("f", "function ${1}(${2}) {\n\t${3}\n}", {}),
	-- anonymous function
	vsc("af", "(${1}) => $0", {}),
	-- skeleton function
	vsc("sf", "function ${1}(${2}): ${3:void} {\n\t${0:throw new Error('Not implemented')}\n}", {}),
	-- throw
	vsc("tn", "throw new Error(${0})", {}),
	-- comments
	vsc("jsdoc", "/**\n * ${0}\n */", {}),
	vsc("/", "/* ${0} */", {}),
	vsc("/**", "/** ${0} */", {}),
	vsc("eld", "/* eslint-disable-next-line ${0} */", {}),
	-- template string variable
	vsc({ trig = "v", wordTrig = false }, "\\${${1}}", {}),
	-- verbose undefined checks
	vsc("=u", "=== undefined", {}),
	vsc("!u", "!== undefined", {}),
}

ls.add_snippets("all", {
	s("date", { i(1, os.date("%Y-%m-%d")) }),
	vsc({ name = "random number", trig = "rn" }, "$RANDOM", {}),
	vsc({ name = "random hex number", trig = "rh" }, "$RANDOM_HEX", {}),
	vsc({ name = "random uuid", trig = "uuid" }, "$UUID", {}),
	vsc("filename", "$TM_FILENAME", {}),
	vsc("filepath", "$TM_FILEPATH", {}),
	vsc({ trig = "v", wordTrig = false }, "\\${${1}}", {}),
	vsc({ name = "return", trig = "r" }, "return ${0}", {}),
})

ls.add_snippets("markdown", {
	-- task
	vsc("t", "- [ ] ${0}", {}),
	-- code blocks
	vsc("c", "```\n${1}\n```", {}),
	vsc("cj", "```json\n${1}\n```", {}),
	vsc("ct", "```typescript\n${1}\n```", {}),
	vsc("cp", "```python\n${1}\n```", {}),
	vsc("cs", "```sh\n${1}\n```", {}),
})

ls.add_snippets("javascript", js_snippets)
ls.add_snippets("typescript", js_snippets)
ls.add_snippets("javascriptreact", js_snippets)
ls.add_snippets("typescriptreact", js_snippets)
-- }}}

-- {{{ tree sitter
require("nvim-treesitter.configs").setup({
	highlight = {
		enable = true,
		disable = { "bash" },
	},
	indent = { enable = true, disable = { "python" } },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<c-space>",
			node_incremental = "<c-space>",
		},
	},
	playground = { enable = true },
	context_commentstring = { enable = true },
	textobjects = {
		select = {
			enable = true,
			lookahead = true,
			keymaps = {
				["aa"] = "@parameter.outer",
				["ia"] = "@parameter.inner",
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
				["a/"] = "@comment.outer",
			},
		},
		swap = {
			enable = true,
			swap_next = {
				["<leader>pl"] = "@parameter.inner",
			},
			swap_previous = {
				["<leader>ph"] = "@parameter.inner",
			},
		},
		move = {
			enable = true,
			set_jumps = true,
			goto_next_start = { ["]m"] = "@function.outer" },
			goto_next_end = { ["]M"] = "@function.outer" },
			goto_previous_start = { ["[m"] = "@function.outer" },
			goto_previous_end = { ["[M"] = "@function.outer" },
		},
	},
})
-- }}}

-- {{{ telescope
local actions = require("telescope.actions")
local action_layout = require("telescope.actions.layout")
local telescope = require("telescope")
telescope.setup({
	defaults = {
		layout_config = { prompt_position = "top" },
		sorting_strategy = "ascending",
		layout_strategy = "flex",
		dynamic_preview_title = true,
		mappings = {
			i = {
				["<C-g>"] = action_layout.toggle_preview,
				["<C-x>"] = false,
				["<C-s>"] = actions.select_horizontal,
				["<esc>"] = actions.close,
			},
		},
	},
	pickers = {
		buffers = {
			mappings = {
				i = {
					["<C-x>"] = actions.delete_buffer,
				},
			},
		},
	},
	extensions = {
		fzf = {
			fuzzy = true,
			override_generic_sorter = true,
			override_file_sorter = true,
		},
		undo = {
			use_delta = false,
		},
		zoxide = {
			mappings = {
				default = {
					action = function(selection)
						vim.cmd("cd " .. selection.path)
						require("telescope.builtin").find_files()
					end,
				},
			},
		},
	},
})
telescope.load_extension("fzf")
telescope.load_extension("manix")
telescope.load_extension("undo")
telescope.load_extension("zoxide")

vim.keymap.set("n", "<leader>fU", telescope.extensions.undo.undo, { desc = "search telescope history" })
vim.keymap.set("n", "<leader>fz", telescope.extensions.zoxide.list, { desc = "cd with zoxide" })
vim.keymap.set("n", ",z", telescope.extensions.zoxide.list, { desc = "cd with zoxide" })
-- }}}

-- {{{ misc and UI stuff
require("hop").setup()
M.map("n", "s", ":HopChar1<cr>")
M.map("n", "S", ":HopWordMW<cr>")

M.map("n", "<leader>u", "<cmd>MundoToggle<cr>")
vim.g.mundo_preview_bottom = 1
vim.g.mundo_width = 40
vim.g.mundo_preview_height = 20

require("neodev").setup({})

require("various-textobjs").setup({ useDefaultKeymaps = true })
-- }}}

-- {{{ git + fugitive
require("octo").setup()

local gitsigns = require("gitsigns")
gitsigns.setup({
	current_line_blame_opts = { delay = 0 },
})

-- Navigation
vim.keymap.set("n", "]c", function()
	if vim.wo.diff then
		return "]c"
	end
	vim.schedule(gitsigns.next_hunk)
	return "<Ignore>"
end, { expr = true, desc = "next hunk" })
vim.keymap.set("n", "[c", function()
	if vim.wo.diff then
		return "[c"
	end
	vim.schedule(gitsigns.prev_hunk)
	return "<Ignore>"
end, { expr = true, desc = "prev hunk" })

-- Actions
vim.keymap.set({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", { desc = "stage hunk" })
vim.keymap.set({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", { desc = " reset hunk" })
vim.keymap.set("n", "<leader>hu", gitsigns.undo_stage_hunk, { desc = "undo stage buffer" })
vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, { desc = "preview hunk" })
vim.keymap.set("n", "<leader>hb", function()
	gitsigns.blame_line({ full = true })
end, { desc = "full blame" })
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
		vim.opt_local.foldlevel = 99
		vim.cmd([[ nnoremap <buffer> <Tab> = ]])
	end,
})
-- }}}

-- {{{ terminal
M.map("t", "<Esc>", [[<C-\><C-n>]])

local terminal_augroup = vim.api.nvim_create_augroup("TerminalSetup", {})

-- darken terminal background when in insert mode
vim.api.nvim_create_autocmd({ "TermEnter" }, {
	group = terminal_augroup,
	command = "set winhighlight=Normal:ActiveTermBg",
})
vim.api.nvim_create_autocmd({ "TermLeave" }, {
	group = terminal_augroup,
	command = "set winhighlight=Normal:InactiveTermBg",
})

vim.api.nvim_create_autocmd({ "TermOpen" }, {
	group = terminal_augroup,
	callback = function()
		-- stops terminal side scrolling
		vim.cmd([[ setlocal nonumber norelativenumber signcolumn=no ]])

		-- ctrl-c, ctrl-p, ctrl-n, enter should all be passed through from normal mode
		vim.cmd([[ nnoremap <buffer> <C-C> i<C-C><C-\><C-n> ]])
		vim.cmd([[ nnoremap <buffer> <C-P> i<C-P><C-\><C-n> ]])
		vim.cmd([[ nnoremap <buffer> <C-N> i<C-N><C-\><C-n> ]])
		vim.cmd([[ nnoremap <buffer> <CR> i<CR><C-\><C-n> ]])
	end,
})
-- }}}

-- {{{ pro debugging
require("debugprint").setup()

require("which-key").register({
	name = "debugprint",
	p = "plain below",
	P = "plain above",
	v = "variable below",
	V = "variable above",
	o = "variable below [motion]",
	O = "variable above [motion]",
	x = { require("debugprint").deleteprints, "clear debug prints" },
}, {
	prefix = "g?",
})
-- }}}

-- {{{ regular debugging
require("dapui").setup({})
require("dap-go").setup()
require("nvim-dap-virtual-text").setup({})

vim.keymap.set("n", "<space>dR", require("dap").clear_breakpoints, { desc = "clear breakpoints" })
vim.keymap.set("n", "<space>db", require("dap").toggle_breakpoint, { desc = "toggle breakpoint" })
vim.keymap.set("n", "<space>dc", require("dap").continue, { desc = "continue" })
vim.keymap.set("n", "<space>dr", require("dap").repl.open, { desc = "repl" })
vim.keymap.set("n", "<space>di", require("dap").step_into, { desc = "step into" })
vim.keymap.set("n", "<space>do", require("dap").step_over, { desc = "step over" })
vim.keymap.set("n", "<space>dt", require("dap").step_out, { desc = "step out" })

vim.keymap.set("n", "<space>du", require("dapui").toggle, { desc = "toggle" })
vim.keymap.set("n", "<space>dc", require("dap").run_to_cursor, { desc = "run to cursor" })
-- }}}

-- {{{ Formatting
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = vim.api.nvim_create_augroup("FormatJsTs", {}),
	pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
	command = "Neoformat",
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = vim.api.nvim_create_augroup("FormatMyNotes", {}),
	pattern = "*Documents/notes/**/*.md",
	command = "Neoformat",
})
-- }}}

-- {{{ refactoring
require("refactoring").setup({})

-- helper fn to make passing these functions to which_key easier
local function refactor(name)
	return function()
		require("refactoring").refactor(name)
	end
end

require("which-key").register({
	name = "refactoring",
	b = { refactor("Extract Block"), "Extract Block" },
	i = { refactor("Inline Variable"), "Inline Variable" },
}, {
	prefix = "<leader>r",
})
require("which-key").register({
	name = "refactoring",
	e = { refactor("Extract Function"), "Extract Function" },
	f = { refactor("Extract Function To File"), "Extract Function To File" },
	v = { refactor("Extract Variable"), "Extract Variable" },
	i = { refactor("Inline Variable"), "Inline Variable" },
}, {
	prefix = "<leader>r",
	mode = "v",
})
-- }}}

-- {{{ fancy tree sitter stuff
require("syntax-tree-surfer").setup()

-- Visual Selection from Normal Mode
vim.keymap.set("n", "vx", "<cmd>STSSelectMasterNode<cr>")
vim.keymap.set("n", "vn", "<cmd>STSSelectCurrentNode<cr>")

-- Select Nodes in Visual Mode
vim.keymap.set("x", "J", "<cmd>STSSelectNextSiblingNode<cr>")
vim.keymap.set("x", "K", "<cmd>STSSelectPrevSiblingNode<cr>")
vim.keymap.set("x", "H", "<cmd>STSSelectParentNode<cr>")
vim.keymap.set("x", "L", "<cmd>STSSelectChildNode<cr>")

-- Swapping Nodes in Visual Mode
vim.keymap.set("x", "<A-j>", "<cmd>STSSwapNextVisual<cr>")
vim.keymap.set("x", "<A-k>", "<cmd>STSSwapPrevVisual<cr>")
vim.keymap.set("v", "<C-j>", "<cmd>STSSwapNextVisual<cr>")
vim.keymap.set("v", "<C-k>", "<cmd>STSSwapPrevVisual<cr>")
-- }}}

-- vim:foldmethod=marker

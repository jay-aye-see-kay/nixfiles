-- helpers {{{
local function merge(t1, t2)
	return vim.tbl_extend("force", t1, t2)
end

local function make_directed_maps(command_desc, command)
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

local function exec(command)
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

local function uuid()
	local res = exec([[ python -c "import uuid, sys; sys.stdout.write(str(uuid.uuid4()))" ]])
	return res[1]
end

local function _noremap(mode, from, to)
	vim.api.nvim_set_keymap(mode, from, to, { noremap = true, silent = true })
end

local function noremap(from, to)
	_noremap("", from, to)
end

local function nnoremap(from, to)
	_noremap("n", from, to)
end

local function inoremap(from, to)
	_noremap("i", from, to)
end

local function vnoremap(from, to)
	_noremap("v", from, to)
end
-- }}}

-- init file setup {{{
local all_config_files = { "*code/neovim-flake/*.lua" }
local init_augroup = vim.api.nvim_create_augroup("InitFilesSetup", {})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	group = init_augroup,
	pattern = all_config_files,
	command = "setlocal foldmethod=marker",
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = init_augroup,
	pattern = all_config_files,
	command = "Neoformat stylua",
})
-- }}}

-- basic core stuff {{{

-- faster window movements
nnoremap("<c-h>", "<c-w>h")
nnoremap("<c-j>", "<c-w>j")
nnoremap("<c-k>", "<c-w>k")
nnoremap("<c-l>", "<c-w>l")

-- disable ex mode
nnoremap("Q", "<nop>")
nnoremap("gQ", "<nop>")

inoremap("<c-a>", "<nop>") -- disable insert repeating
nnoremap("Y", "y$") -- make Y behave like C and D

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

-- prefer spaces over tabs, unless working on MSH files
vim.cmd([[ set tabstop=2 ]])
vim.cmd([[ set softtabstop=2 ]])
vim.cmd([[ set shiftwidth=2 ]])

vim.api.nvim_create_autocmd({ "TextYankPost" }, {
	group = vim.api.nvim_create_augroup("HighlightOnYank", {}),
	command = "silent! lua vim.highlight.on_yank()",
})

-- modern copy paste keymaps
inoremap("<C-v>", "<C-r>+")
vnoremap("<C-c>", '"+y')

-- stuff from https://github.com/mjlbach/defaults.nvim

--Remap space as leader key
noremap("<Space>", "")
vim.g.mapleader = " "
vim.g.maplocalleader = " "

--Set highlight on search
vim.o.hlsearch = false
vim.o.incsearch = true

vim.o.inccommand = "nosplit" --Incremental live completion
vim.wo.number = true --Make line numbers default
vim.o.hidden = true --Do not save when switching buffers
vim.o.mouse = "a" --Enable mouse mode
vim.o.breakindent = true --Enable break indent
vim.wo.signcolumn = "yes"

--Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

--Set colorscheme (order is important here)
vim.o.termguicolors = true
vim.cmd([[ colorscheme nvcode ]])

vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 4
vim.opt.wrap = false

vim.api.nvim_create_autocmd({ "FileType" }, {
	group = vim.api.nvim_create_augroup("FzfEscapeBehavior", {}),
	pattern = "fzf",
	command = "tnoremap <buffer> <ESC> <ESC>",
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
	-- TODO clean this per lsp setup logic up, jsonls properly
	local settings = {}
	-- local filetypes = {}
	if lsp == "jsonls" then
		settings.json = {
			schemas = require("schemastore").json.schemas(),
		}
		-- filetypes = { "json", "jsonc" }
	elseif lsp == "sumneko_lua" then
		settings.Lua = {
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim" } },
			workspace = { library = vim.api.nvim_get_runtime_file("", true) },
			telemetry = { enable = false },
		}
	end
	require("lspconfig")[lsp].setup({
		flags = {
			-- This will be the default in neovim 0.7+
			debounce_text_changes = 150,
		},
		settings = settings,
		-- filetypes = filetypes,
		on_attach = function(client)
			if lsp == "tsserver" then
				local ts_utils = require("nvim-lsp-ts-utils")
				ts_utils.setup({})
				ts_utils.setup_client(client)
			end
		end,
	})
end

nnoremap("gd", "<CMD>Telescope lsp_definitions<CR>")
nnoremap("gr", "<CMD>Telescope lsp_references<CR>")
nnoremap("gy", "<CMD>Telescope lsp_type_definitions<CR>")
nnoremap("gh", "<CMD>lua vim.lsp.buf.hover()<CR>")
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

require("fidget").setup()

require("lsp_signature").setup()

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
		["<CR>"] = cmp.mapping.confirm({ select = true }),
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
		vim.api.nvim_buf_set_keymap(0, "n", "j", "gj", { silent = true })
		vim.api.nvim_buf_set_keymap(0, "n", "k", "gk", { silent = true })
	end,
})

local function open_logbook(days_from_today)
	local date_offset = (days_from_today or 0) * 24 * 60 * 60
	local filename = os.date("%Y-%m-%d-%A", os.time() + date_offset) .. ".org"
	local todays_journal_file = "~/Documents/org/logbook/" .. filename
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
			["Z"] = "expand_all_nodes",
		},
	},
	filesystem = {
		hijack_netrw_behavior = "open_current",
		use_libuv_file_watcher = true,
		follow_current_file = true,
		window = {
			mappings = {
				["H"] = "navigate_up",
				["L"] = "set_root",
				-- ["H"] = "toggle_hidden",
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
nnoremap("<c-s>", "<cmd>w<cr>")

local directed_keymaps = {
	git_status = make_directed_maps("Git Status", "Gedit :"),
	new_terminal = make_directed_maps("New terminal", "terminal"),
	todays_notepad = make_directed_maps("Today's notepad", "LogbookToday"),
	yesterdays_notepad = make_directed_maps("Yesterday's notepad", "LogbookYesterday"),
	tomorrows_notepad = make_directed_maps("Tomorrow's notepad", "LogbookTomorrow"),
	file_explorer = make_directed_maps("File explorer", "Neotree reveal current"),
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
		j = { "<cmd>lua vim.diagnostic.goto_next()<cr>", "Next diagnostic" },
		k = { "<cmd>lua vim.diagnostic.goto_prev()<cr>", "Prev diagnostic" },
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
	git = merge(directed_keymaps.git_status, {
		name = "+git",
		g = { "<Cmd>Telescope git_commits<CR>", "🔭 commits" },
		c = { "<Cmd>Telescope git_bcommits<CR>", "🔭 buffer commits" },
		b = { "<Cmd>Telescope git_branches<CR>", "🔭 branches" },
		R = { "<Cmd>Gitsigns reset_hunk<CR>", "reset hunk" },
		p = { "<Cmd>Gitsigns preview_hunk<CR>", "preview hunk" },
	}),
	terminal = merge(directed_keymaps.new_terminal, {
		name = "+terminal",
	}),
	explorer = merge(directed_keymaps.file_explorer, {
		name = "+file explorer",
		e = { "<cmd>Neotree toggle<cr>", "toggle side file tree" },
	}),
	notes = merge(directed_keymaps.todays_notepad, {
		name = "+notes",
		f = { grep_notes, "🔭 search all notes" },
		y = merge(directed_keymaps.yesterdays_notepad, {
			name = "+Yesterday' notepad",
		}),
		t = merge(directed_keymaps.tomorrows_notepad, {
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
local function snip_map(from, to)
	vim.api.nvim_set_keymap("i", from, to, {})
	vim.api.nvim_set_keymap("s", from, to, {})
end

snip_map("<C-j>", "<Plug>luasnip-expand-snippet")
snip_map("<C-l>", "<Plug>luasnip-jump-next")
snip_map("<C-h>", "<Plug>luasnip-jump-prev")

local ls = require("luasnip")
local l = require("luasnip.extras").lambda
local f = ls.function_node
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
	vsc("ue", "useEffect(() => {\n\t${1}\n}, [${0}])"),
	-- basics + keywords
	vsc("c", "const ${1} = ${0}"),
	vsc("l", "let ${1} = ${0}"),
	vsc("r", "return ${0}"),
	vsc("e", "export ${0}"),
	vsc("aw", "await ${0}"),
	vsc("as", "async ${0}"),
	vsc("d", "debugger"),
	-- function
	vsc("f", "function ${1}(${2}) {\n\t${3}\n}"),
	-- anonymous function
	vsc("af", "(${1}) => $0"),
	-- skeleton function
	vsc("sf", "function ${1}(${2}): ${3:void} {\n\t${0:throw new Error('Not implemented')}\n}"),
	-- throw
	vsc("tn", "throw new Error(${0})"),
	-- comments
	vsc("jsdoc", "/**\n * ${0}\n */"),
	vsc("/", "/* ${0} */"),
	vsc("/**", "/** ${0} */"),
	vsc("eld", "/* eslint-disable-next-line ${0} */"),
	-- template string variable
	vsc({ trig = "v", wordTrig = false }, "\\${${1}}"),
	-- verbose undefined checks
	vsc("=u", "=== undefined"),
	vsc("!u", "!== undefined"),
}

ls.add_snippets("all", {
	s("date", { i(1, os.date("%Y-%m-%d")) }),
	s("uuid", { f(uuid, {}) }),
	vsc("filename", "$TM_FILENAME"),
	vsc("filepath", "$TM_FILEPATH"),
	vsc({ trig = "v", wordTrig = false }, "\\${${1}}"),
})

ls.add_snippets("markdown", {
	-- task
	vsc("t", "- [ ] ${0}"),
	-- code blocks
	vsc("c", "```\n${1}\n```"),
	vsc("cj", "```json\n${1}\n```"),
	vsc("ct", "```typescript\n${1}\n```"),
	vsc("cp", "```python\n${1}\n```"),
	vsc("cs", "```sh\n${1}\n```"),
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
	},
	incremental_selection = { enable = true },
	playground = { enable = true },
	context_commentstring = { enable = true },
	textobjects = {
		select = {
			enable = true,
			keymaps = {
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
	},
})

local actions = require("telescope.actions")
local action_layout = require("telescope.actions.layout")
require("telescope").setup({
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
	},
})
require("telescope").load_extension("fzf")
-- }}}

-- {{{ misc and UI stuff
require("hop").setup()
nnoremap("s", ":HopChar1<cr>")
nnoremap("S", ":HopWordMW<cr>")

nnoremap("<leader>u", "<cmd>MundoToggle<cr>")
vim.g.mundo_preview_bottom = 1
vim.g.mundo_width = 40
vim.g.mundo_preview_height = 20

require("scrollbar").setup()
-- }}}

-- {{{ git + fugitive
vim.api.nvim_create_autocmd({ "FileType" }, {
	group = vim.api.nvim_create_augroup("FugitiveSetup", {}),
	pattern = "fugitive",
	callback = function()
		vim.opt_local.foldlevel = 99
		vim.cmd([[ nnoremap <buffer> <Tab> = ]])
	end,
})
-- }}}

-- {{{ status and winbar
-- global statusline; only works on neovim 0.7+
vim.cmd([[ set laststatus=3 ]])

vim.api.nvim_create_autocmd({ "FileType" }, {
	group = vim.api.nvim_create_augroup("WinbarSetup", {}),
	callback = function()
		local exclude_buftypes = {
			"terminal",
			"nofile",
			"prompt",
			"help",
			"quickfix",
		}
		local exclude_filetypes = {
			"fugitive",
			"gitcommit",
		}
		local should_exclude = vim.tbl_contains(exclude_filetypes, vim.bo.filetype)
			or vim.tbl_contains(exclude_buftypes, vim.bo.buftype)
		if not should_exclude then
			pcall(vim.api.nvim_set_option_value, "winbar", "%=%m %f", { scope = "local" })
		else
			vim.opt_local.winbar = nil
		end
	end,
})
-- }}} status and winbar

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

-- }}} pro debugging

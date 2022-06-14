-- helpers {{{

-- usage:
-- augroup('my_group', {
--   { "BufEnter", "*.md", "set filetype=markdown" },
-- })
local function augroup(group_name, definition)
	vim.api.nvim_command("augroup " .. group_name)
	vim.api.nvim_command("autocmd!")
	for _, def in ipairs(definition) do
		local command = table.concat(vim.tbl_flatten({ "autocmd", def }), " ")
		vim.api.nvim_command(command)
	end
	vim.api.nvim_command("augroup END")
end

-- https://stackoverflow.com/a/7470789/7164888
-- TODO use vim.tbl_extend() instead
local function merge(t1, t2)
	for k, v in pairs(t2) do
		if (type(v) == "table") and (type(t1[k] or false) == "table") then
			merge(t1[k], t2[k])
		else
			t1[k] = v
		end
	end
	return t1
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
	local file = io.popen(command, "r")
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
local all_config_files = "*/neovim/init.lua,*/neovim/plugins.lua"
augroup("init_file_setup", {
	{ "BufNewFile,BufRead", all_config_files, "setlocal foldmethod=marker" },
	{ "BufWritePre", all_config_files, "Neoformat stylua" },
})
-- TODO move somewhere?
augroup("natural_movement_in_text_files", {
	{ "FileType", "text,markdown,org", "nnoremap j gj" },
	{ "FileType", "text,markdown,org", "nnoremap k gk" },
	{ "FileType", "text,markdown,org", "setlocal wrap" },
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

augroup("only_show_cursorline_on_focued_window", {
	{ "VimEnter,WinEnter,BufWinEnter ", "*", "setlocal cursorline" },
	{ "WinLeave", "*", "setlocal nocursorline" },
})

-- prefer spaces over tabs, unless working on MSH files
vim.cmd([[ set tabstop=2 ]])
vim.cmd([[ set softtabstop=2 ]])
vim.cmd([[ set shiftwidth=2 ]])
augroup("msh_tabs", {
	{ "BufEnter", "*", "set expandtab" },
	{ "BufEnter", "*/code/msh/*", "set noexpandtab" },
})

augroup("highlight_on_yank", {
	{ "TextYankPost", "*", "silent! lua vim.highlight.on_yank()" },
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

augroup("fzfDefaultEscapeBehavior", {
	{ "FileType", "fzf", "tnoremap <buffer> <ESC> <ESC>" },
})
-- }}}

-- lsp {{{
local lsp_servers = {
	"bashls",
	"cssls",
	"dockerls",
	"html",
	"jsonls",
	"pyright", --
	"rnix",
	"rust_analyzer",
	"solargraph", --
	"sumneko_lua",
	"tsserver",
	"vimls",
	"yamlls", --
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
	elseif lsp == "" then
		settings.Lua = {
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

function LspFormat()
	vim.lsp.buf.formatting_sync()
	local tsserver_filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" }
	if vim.tbl_contains(tsserver_filetypes, vim.bo.filetype) then
		vim.cmd([[ TSLspOrganizeSync ]])
	end
end

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
-- }}}

-- completions {{{
vim.g.copilot_node_command = "/usr/bin/node"
vim.g.copilot_no_tab_map = true
vim.g.copilot_enabled = false
vim.cmd([[ imap <silent><script><expr> <C-k> copilot#Accept() ]])

function ToggleCopilot()
	if vim.fn["copilot#Enabled"]() == 1 then
		vim.cmd([[ Copilot disable ]])
	else
		vim.cmd([[ Copilot enable ]])
	end
	vim.cmd([[ Copilot status ]])
end

vim.cmd([[ set completeopt=menu,menuone,noselect ]])

local cmp = require("cmp")

cmp.setup({
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-y>"] = cmp.mapping.confirm({ select = true }),
		["<C-f>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
		["<C-e>"] = cmp.mapping({
			i = cmp.mapping.abort(),
			c = cmp.mapping.close(),
		}),
		-- ['<CR>'] = cmp.mapping.confirm({ select = true }),
		-- ['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
		-- ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
		{ name = "nvim_lua" },
		{ name = "orgmode" },
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
augroup("orgmode-setup", {
	{ "FileType", "org", "setlocal conceallevel=2" },
	{ "FileType", "org", "setlocal concealcursor=nc" },
})

local function org_capture_task()
	local Templates = require("orgmode.capture.templates")
	local task_template = Templates:new():get_list()["t"]
	require("orgmode").action("capture.open_template", task_template)
end

vim.g.markdown_fenced_languages = {
	"bash=sh",
	"c",
	"cpp",
	"css",
	"elm",
	"fish",
	"go",
	"html",
	"java",
	"javascript",
	"js=javascript",
	"json",
	"lisp",
	"lua",
	"python",
	"ruby",
	"rust",
	"sh",
	"ts=typescript",
	"typescript",
	"yaml",
}

vim.g.bullets_checkbox_markers = " .oOx"
vim.g.wiki_root = "~/Documents/notes"
vim.g.markdown_folding = true

nnoremap("glt", "<cmd>ToggleCheckbox<cr>") -- TODO: create or toggle checkbox

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

function WhichkeyOrgmode()
	require("which-key").register({
		name = "orgmode keymap lables",
		["<leader>"] = {
			o = {
				o = "open at point",
				r = "refile",
				t = "set tags",
				e = "export",
				A = "archive tag",
				K = "move subtree up",
				J = "move subtree down",
				["'"] = "edit in special buffer",
				["$"] = "archive subtree",
				[","] = "change priority",
				["*"] = "toggle heading",
				i = {
					name = "+change things",
					d = "change date under cursor",
					h = "insert heading respect content",
					T = "insert todo heading",
					t = "insert todo heading respect content",
					s = "change schedule",
					["."] = "change time stamp",
					["!"] = "change time stamp inactive",
				},
				x = {
					name = "+clocking",
					i = "clock in",
					o = "clock out",
					q = "cancel active clock",
					j = "goto clocked in header",
					e = "set effort for current header",
				},
			},
		},
		c = {
			i = {
				d = "ORG change date",
				R = "ORG priority up",
				r = "ORG priority down",
				t = "ORG change TODO state",
				T = "ORG cycle TODO state back",
			},
		},
	}, {
		buffer = vim.api.nvim_get_current_buf(),
	})
end
augroup("whichkeyOrgmode", {
	{ "FileType", "org", "lua WhichkeyOrgmode()" },
})
-- }}}

-- keymaps {{{
nnoremap("<c-s>", "<cmd>w<cr>")

local directed_keymaps = {
	git_status = make_directed_maps("Git Status", "Gedit :"),
	new_terminal = make_directed_maps("New terminal", "terminal"),
	todays_notepad = make_directed_maps("Today's notepad", "LogbookToday"),
	yesterdays_notepad = make_directed_maps("Yesterday's notepad", "LogbookYesterday"),
	tomorrows_notepad = make_directed_maps("Tomorrow's notepad", "LogbookTomorrow"),
	file_explorer = make_directed_maps("File explorer", "Fern . -reveal=%"),
	roaming_file_explorer = make_directed_maps("File explorer (focused on file's directory)", "Fern %:h -reveal=%"),
}

--- grep through old markdown notes
local grep_notes = function()
	require("telescope.builtin").live_grep({ cwd = "$HOME/Documents/notes" })
end

--- grep through new orgmode notes (still need to learn if orgmode's advanced search is better)
local grep_org_files = function()
	require("telescope.builtin").live_grep({ cwd = "$HOME/Documents/org" })
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
		f = { "<cmd>lua LspFormat()<cr>", "Prev Diagnostic" },
		c = { "<cmd>call v:lua.ToggleCopilot()<cr>", "Toggle Copilot" },

		-- HACK: pop into insert mode after to trigger lsp applying settings
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
		h = { telescope_fns.help_tags, "🔭 help tags" },
		c = { telescope_fns.commands, "🔭 commands" },
		o = { telescope_fns.oldfiles, "🔭 oldfiles" },
		l = { telescope_fns.current_buffer_fuzzy_find, "🔭 buffer lines" },
		w = { telescope_fns.spell_suggest, "🔭 spelling suggestions" },
		s = { telescope_fns.symbols, "🔭 unicode and emoji symbols" },
		a = { "<Cmd>FzfLua live_grep<CR>", "FZF full text search" },
		u = { "<Cmd>FzfLua grep_cword<CR>", "FZF word under cursor" },
		U = { "<Cmd>FzfLua grep_cWORD<CR>", "FZF WORD under cursor" },
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
		["e"] = merge(directed_keymaps.roaming_file_explorer, {
			name = "+in current file' directory",
		}),
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
	vim_config = {
		name = "+vim config",
		c = {
			"<cmd>tabedit $MYVIMRC | vsplit " .. vim.fn.stdpath("config") .. "/plugins.lua<cr>",
			"Edit config in new tab",
		},
		r = { "<cmd>source $MYVIMRC | PackerCompile<cr>", "Reload config" },
		s = { "<cmd>PackerSync<cr>", "Packer sync" },
	},
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
	org = {
		name = "+org",
		c = "Org capture",
		a = "Org agenda",
		f = { grep_org_files, "Grep org files" },
	},
}

local which_key = require("which-key")
vim.opt.timeoutlen = 250

which_key.register({
	e = main_keymap.explorer,
	f = main_keymap.finder,
	g = main_keymap.git,
	l = main_keymap.lsp,
	t = main_keymap.terminal,
	n = main_keymap.notes,
	v = main_keymap.vim_config,
	m = main_keymap.misc,
	o = main_keymap.org,
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
	["."] = main_keymap.explorer["."], -- Fern .
	[">"] = main_keymap.explorer.e["."], -- Fern . (relative to file)
	c = { org_capture_task, "Capture task" },
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

ls.snippets = {
	all = {
		s("date", { i(1, os.date("%Y-%m-%d")) }),
		s("uuid", { f(uuid, {}) }),
		vsc("filename", "$TM_FILENAME"),
		vsc("filepath", "$TM_FILEPATH"),
		vsc({ trig = "v", wordTrig = false }, "\\${${1}}"),
		vsc({ trig = "(", wordTrig = false }, "(${1})${0}"),
		vsc({ trig = "{", wordTrig = false }, "{${1}}${0}"),
		vsc({ trig = "[", wordTrig = false }, "[${1}]${0}"),
		vsc({ trig = "<", wordTrig = false }, "<${1}>${0}"),
	},
	markdown = {
		-- task
		vsc("t", "- [ ] ${0}"),
		-- code blocks
		vsc("c", "```\n${1}\n```"),
		vsc("cj", "```json\n${1}\n```"),
		vsc("ct", "```typescript\n${1}\n```"),
		vsc("cp", "```python\n${1}\n```"),
		vsc("cs", "```sh\n${1}\n```"),
	},
	org = {
		-- todo
		vsc("t", "- [ ] ${0}"),
		-- code blocks
		vsc("c", "#+BEGIN_SRC ${1}\n${0}\n#+END_SRC\n"),
		vsc("cj", "#+BEGIN_SRC json\n${0}\n#+END_SRC\n"),
		vsc("ct", "#+BEGIN_SRC typescript\n${0}\n#+END_SRC\n"),
		vsc("cp", "#+BEGIN_SRC python\n${0}\n#+END_SRC\n"),
	},
	javascript = js_snippets,
	typescript = js_snippets,
	javascriptreact = js_snippets,
	typescriptreact = js_snippets,
}

-- }}}

--
-- END old init.lua
--

-- {{{ imported from plugin config
require("nvim-treesitter.configs").setup({
	highlight = {
		enable = true,
		disable = { "org" },
		additional_vim_regex_highlighting = { "org" },
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

local todays_journal_file = "~/Documents/org/logbook/" .. os.date("%Y-%m-%d-%A") .. ".org"
require("orgmode").setup_ts_grammar()
require("orgmode").setup({
	org_agenda_files = {
		"~/Documents/org/*",
		"~/Documents/org/logbook/*",
		"~/Documents/org/projects/*",
	},
	org_default_notes_file = todays_journal_file,
	org_todo_keywords = { "TODO(t)", "INPROGRESS(p)", "WAITING(w)", "|", "DONE(d)", "CANCELLED(c)" },
	org_todo_keyword_faces = {
		TODO = ":foreground #CE9178 :weight bold :underline on",
		NEXT = ":foreground #DCDCAA :weight bold :underline on",
		INPROGRESS = ":foreground #729CB3 :weight bold :underline on",
		DONE = ":foreground #81B88B :weight bold :underline on",
	},
	org_agenda_templates = {
		u = {
			description = "Unfiled task",
			template = "\n* TODO %?\n  CREATED: %U",
			target = "~/Documents/org/refile.org",
		},
		l = {
			description = "Logbook note",
			template = "\n%?",
		},
		t = {
			description = "Task",
			template = "\n* TODO %?\n  CREATED: %U",
		},
		T = {
			description = "Urgent task",
			template = "\n* TODO [#A] %?\n  DEADLINE: %t\n  CREATED: %U",
		},
		i = {
			description = "Idea",
			template = "\n** %?\n",
			target = "~/Documents/org/ideas.org",
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

require("hop").setup()
vim.api.nvim_set_keymap("n", "s", ":HopChar1<cr>", { silent = true })
vim.api.nvim_set_keymap("n", "S", ":HopWord<cr>", { silent = true })

vim.api.nvim_set_keymap("n", "<leader>u", "<cmd>MundoToggle<cr>", { silent = true })
vim.g.mundo_preview_bottom = 1
vim.g.mundo_width = 40
vim.g.mundo_preview_height = 20

require("which-key").setup({
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
-- }}}

-- {{{ status and winbar
vim.cmd([[ set laststatus=3 ]]) -- global statusline; only works on neovim 0.7+
vim.api.nvim_create_autocmd({
	"DirChanged",
	"CursorMoved",
	"BufWinEnter",
	"BufFilePost",
	"InsertEnter",
	"BufWritePost",
}, {
	callback = function()
		local exclude_buftypes = { "terminal" }
		local exclude_filetypes = {
			"help",
			"qf",
			"packer",
			"Trouble",
			"fugitive",
			"gitcommit",
			"fern",
			"Telescope",
			"TelescopePrompt",
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

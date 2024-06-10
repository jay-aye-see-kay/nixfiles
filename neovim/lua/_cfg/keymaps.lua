local h = require("_cfg.helpers")

-- keymaps {{{
-- show the whichkey popup (i.e. which keymaps are available)
vim.keymap.set({ "n", "v", "i" }, "<F1>", "<cmd>WhichKey<cr>")

local directed_keymaps = {
	git_status = h.make_directed_maps("Git Status", "Gedit :"),
	new_terminal = h.make_directed_maps("New terminal", "terminal"),
	todays_notepad = h.make_directed_maps("Today's notepad", "LogbookToday"),
	yesterdays_notepad = h.make_directed_maps("Yesterday's notepad", "LogbookYesterday"),
	tomorrows_notepad = h.make_directed_maps("Tomorrow's notepad", "LogbookTomorrow"),
	file_explorer = h.make_directed_maps("File explorer", "Neotree reveal current"),
}

--- grep through old markdown notes
local grep_notes = function()
	require("telescope.builtin").live_grep({ cwd = "$HOME/notes" })
end

--- git files, falling back onto all files in cwd if not in a git repo
local function project_files()
	local ok = pcall(require("telescope.builtin").git_files)
	if not ok then
		require("telescope.builtin").find_files()
	end
end

local main_keymap = {
	lsp = {
		name = "+lsp",
		a = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code action" },
		r = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename symbol" },
		d = { "<cmd>Telescope lsp_document_diagnostics<cr>", "Show document diagnostics" },
		D = { "<cmd>Telescope lsp_workspace_diagnostics<cr>", "Show workspace diagnostics" },
		t = { "<cmd>TroubleToggle<cr>", "Show workspace diagnostics" },
		i = { "<cmd>LspInfo<cr>", "Info" },
		f = { "<cmd>lua vim.lsp.buf.format()<cr>", "Format buffer with LSP" },
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
		f = { "<cmd>Telescope find_files<cr>", "🔭 files" },
		g = { project_files, "🔭 git files" },
		h = {
			function()
				require("telescope.builtin").help_tags({ default_text = vim.fn.expand("<cword>") })
			end,
			"🔭 help tags",
		},
		c = { "<cmd>Telescope commands<cr>", "🔭 commands" },
		o = { "<cmd>Telescope oldfiles<cr>", "🔭 oldfiles" },
		l = { "<cmd>Telescope current_buffer_fuzzy_find<cr>", "🔭 buffer lines" },
		w = { "<cmd>Telescope spell_suggest<cr>", "🔭 spelling suggestions" },
		u = { "<cmd>Telescope grep_string<cr>", "🔭 word under cursor" },
		n = { grep_notes, "🔭 search all notes" },
		i = {
			name = "+in",
			o = {
				function()
					require("telescope.builtin").live_grep({ grep_open_files = true })
				end,
				"🔭 in open buffers",
			},
		},
	},
	git = h.merge(directed_keymaps.git_status, {
		name = "+git",
		g = { "<Cmd>Telescope git_commits<CR>", "🔭 commits" },
		c = { "<Cmd>Telescope git_bcommits<CR>", "🔭 buffer commits" },
		b = { "<Cmd>Telescope git_branches<CR>", "🔭 branches" },
	}),
	terminal = h.merge(directed_keymaps.new_terminal, {
		name = "+terminal",
	}),
	explorer = h.merge(directed_keymaps.file_explorer, {
		name = "+file explorer",
		e = { "<cmd>Neotree toggle<cr>", "toggle side file tree" },
	}),
	notes = h.merge(directed_keymaps.todays_notepad, {
		name = "+notes",
		f = { grep_notes, "🔭 search all notes" },
		y = h.merge(directed_keymaps.yesterdays_notepad, {
			name = "+Yesterday' notepad",
		}),
		t = h.merge(directed_keymaps.tomorrows_notepad, {
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
	l = main_keymap.finder.l, -- buffer lines
	f = main_keymap.finder.f, -- find_files
	o = main_keymap.finder.o, -- old_files
	a = main_keymap.finder.a, -- Rg
	["."] = main_keymap.explorer["."],
	[">"] = main_keymap.explorer.e["."],
}, {
	prefix = ",",
})
-- }}}

-- {{{ hydra keymaps
local Hydra = require("hydra")
Hydra({
	name = "Side scroll",
	mode = "n",
	body = "z",
	heads = {
		{ "h", "5zh" },
		{ "l", "5zl", { desc = "←/→" } },
		{ "H", "zH" },
		{ "L", "zL", { desc = "half screen ←/→" } },
	},
})
Hydra({
	name = "Window resizing",
	mode = "n",
	body = "<c-w>",
	heads = {
		{ "+", "5<c-w>+" },
		{ "-", "5<c-w>-" },
		{ "<", "5<c-w><" },
		{ ">", "5<c-w>>" },
		{ "=", "<C-w>=" },
	},
})
local function tab_func(cmd, arg)
	return function()
		pcall(vim.cmd[cmd], arg)
		require("lualine").refresh()
	end
end
Hydra({
	name = "Windows and tabs",
	mode = "n",
	body = "<leader>w",
	heads = {
		{ "l", tab_func("tabnext"), { desc = "next tab" } },
		{ "h", tab_func("tabprevious"), { desc = "prev tab" } },
		{ "L", tab_func("tabmove", "+1"), { desc = "move tab right" } },
		{ "H", tab_func("tabmove", "-1"), { desc = "move tab left" } },
	},
})
-- }}}

-- {{{ switching text-case (replaced abolish)
local textcase = require("textcase")
local prefix = "ga"
textcase.setup({ prefix = prefix })
-- required until this PR merged https://github.com/johmsalas/text-case.nvim/pull/31
textcase.register_keybindings(prefix, textcase.api.to_snake_case, {
	prefix = prefix,
	quick_replace = "s",
	operator = "os",
	lsp_rename = "S",
})
textcase.register_keybindings(prefix, textcase.api.to_dash_case, {
	prefix = prefix,
	quick_replace = "k",
	operator = "ok",
	lsp_rename = "K",
})
-- }}}

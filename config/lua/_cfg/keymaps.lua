local h = require("_cfg.helpers")

-- keymaps {{{
vim.keymap.set({ "n", "i" }, "<c-s>", "<cmd>w<cr>")

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
		i = {
			name = "+in",
			o = {
				function()
					telescope_fns.live_grep({ grep_open_files = true })
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
-- }}}

-- {{{ custom operators
-- sort from https://github.com/zdcthomas/yop.nvim/wiki/Example-mappings#sorting
require("yop").op_map({ "n", "v" }, ",s", function(lines)
	local sort_without_leading_space = function(a, b)
		local pattern = [[^%W*]]
		return string.gsub(a, pattern, "") < string.gsub(b, pattern, "")
	end
	if #lines == 1 then
		-- If only looking at 1 line, sort that line split by some char gotten from input
		local delimeter = require("yop.utils").get_input("Delimeter: ")
		local split = vim.split(lines[1], delimeter, { trimempty = true })
		table.sort(split, sort_without_leading_space)
		return { require("yop.utils").join(split, delimeter) }
	else
		table.sort(lines, sort_without_leading_space)
		return lines
	end
end)

-- source lines (TODO only enable in vim and lua files)
require("yop").op_map({ "n", "v" }, ",,", function(_, opts)
	vim.cmd(opts.position.first[1] .. "," .. opts.position.last[1] .. " source")
end)
-- }}}

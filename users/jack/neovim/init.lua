-- {{{ plugin config
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
-- }}}


local servers = { 'bashls', 'rust_analyzer', 'sumneko_lua', 'tsserver' }
for _, lsp in pairs(servers) do
  require('lspconfig')[lsp].setup {
    on_attach = on_attach,
    flags = {
      -- This will be the default in neovim 0.7+
      debounce_text_changes = 150,
    }
  }
end

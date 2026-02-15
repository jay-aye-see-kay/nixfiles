-- Treesitter configuration
-- Note: nvim-treesitter and nvim-treesitter-textobjects are provided by Nix
-- They're already in the runtimepath, so we just need to configure them

-- Initialize nvim-treesitter-textobjects (queues the textobjects module definitions)
require("nvim-treesitter-textobjects").init()

-- Initialize nvim-treesitter configs (processes queued module definitions including textobjects)
-- This is normally done by the nvim-treesitter plugin file, but we're loading this before plugin files are sourced
require("nvim-treesitter.configs").init()

require("nvim-treesitter.configs").setup({
	auto_install = false,
	sync_install = false,
	ensure_installed = {},
	ignore_install = {},
	modules = {},
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = { "ruby" },
	},
	indent = { enable = true, disable = { "ruby" } },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<c-space>",
			node_incremental = "<c-space>",
		},
	},
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

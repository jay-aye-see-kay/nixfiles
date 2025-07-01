local plugins = require("nln").plugins

plugins["nvim-treesitter-textobjects"] = {}

plugins["nvim-treesitter"] = {
	dependencies = { "nvim-treesitter-textobjects" },
	config = function()
		require("nvim-treesitter.configs").setup({
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
	end,
}

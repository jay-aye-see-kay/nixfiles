require("nvim-treesitter.configs").setup({
	highlight = {
		enable = true,
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

-- {{{ openapi / other ai code stuff

-- read openai key if it's set in ~/.config/nvim/openai_api_key
local openai_api_key = (function()
	local file = io.open(vim.fn.stdpath("config") .. "/openai_api_key")
	if file then
		for line in file:lines() do
			return line
		end
	end
end)()
if openai_api_key then
	-- currently used by github.com/dpayne/CodeGPT.nvim and chatbot-buffer
	vim.env.OPENAI_API_KEY = openai_api_key
end

-- }}}

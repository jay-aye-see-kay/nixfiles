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
local gp_chat_dir = os.getenv("HOME") .. "/Documents/gp-chats"
require("gp").setup({
	openai_api_key = { "cat", vim.fn.stdpath("config") .. "/openai_api_key" },
	chat_dir = gp_chat_dir,
	chat_conceal_model_params = false,
})

local function keymapOptions(desc)
	return { noremap = true, silent = true, nowait = true, desc = "GPT prompt " .. desc }
end

local grep_gp_chats = function()
	require("telescope.builtin").live_grep({ cwd = gp_chat_dir })
end
vim.keymap.set("n", "<C-g>g", grep_gp_chats, keymapOptions("Grep through old chats"))

-- gp.nvim (ChatGPT) commands
vim.keymap.set({ "n", "i" }, "<C-g>c", "<cmd>GpChatNew vsplit<cr>", keymapOptions("New Chat"))
vim.keymap.set({ "n", "i" }, "<C-g>t", "<cmd>GpChatToggle vsplit<cr>", keymapOptions("Toggle Chat"))
vim.keymap.set({ "n", "i" }, "<C-g>f", "<cmd>GpChatFinder<cr>", keymapOptions("Chat Finder"))

vim.keymap.set("v", "<C-g>c", ":<C-u>'<,'>GpChatNew vsplit<cr>", keymapOptions("Visual Chat New"))
vim.keymap.set("v", "<C-g>p", ":<C-u>'<,'>GpChatPaste<cr>", keymapOptions("Visual Chat Paste"))
vim.keymap.set("v", "<C-g>t", ":<C-u>'<,'>GpChatToggle vsplit<cr>", keymapOptions("Visual Toggle Chat"))

-- Prompt commands
vim.keymap.set({ "n", "i" }, "<C-g>r", "<cmd>GpRewrite<cr>", keymapOptions("Inline Rewrite"))
vim.keymap.set({ "n", "i" }, "<C-g>a", "<cmd>GpAppend<cr>", keymapOptions("Append (after)"))
vim.keymap.set({ "n", "i" }, "<C-g>b", "<cmd>GpPrepend<cr>", keymapOptions("Prepend (before)"))

vim.keymap.set("v", "<C-g>r", ":<C-u>'<,'>GpRewrite<cr>", keymapOptions("Visual Rewrite"))
vim.keymap.set("v", "<C-g>a", ":<C-u>'<,'>GpAppend<cr>", keymapOptions("Visual Append (after)"))
vim.keymap.set("v", "<C-g>b", ":<C-u>'<,'>GpPrepend<cr>", keymapOptions("Visual Prepend (before)"))
vim.keymap.set("v", "<C-g>i", ":<C-u>'<,'>GpImplement<cr>", keymapOptions("Implement selection"))

vim.keymap.set({ "n", "i" }, "<C-g>x", "<cmd>GpContext<cr>", keymapOptions("Toggle Context"))
vim.keymap.set("v", "<C-g>x", ":<C-u>'<,'>GpContext<cr>", keymapOptions("Visual Toggle Context"))

vim.keymap.set({ "n", "i", "v", "x" }, "<C-g>s", "<cmd>GpStop<cr>", keymapOptions("Stop"))
vim.keymap.set({ "n", "i", "v", "x" }, "<C-g>n", "<cmd>GpNextAgent<cr>", keymapOptions("Next Agent"))

-- optional Whisper commands with prefix <C-g>w
vim.keymap.set({ "n", "i" }, "<C-g>ww", "<cmd>GpWhisper<cr>", keymapOptions("Whisper"))
vim.keymap.set("v", "<C-g>ww", ":<C-u>'<,'>GpWhisper<cr>", keymapOptions("Visual Whisper"))

vim.keymap.set({ "n", "i" }, "<C-g>wr", "<cmd>GpWhisperRewrite<cr>", keymapOptions("Whisper Inline Rewrite"))
vim.keymap.set({ "n", "i" }, "<C-g>wa", "<cmd>GpWhisperAppend<cr>", keymapOptions("Whisper Append (after)"))
vim.keymap.set({ "n", "i" }, "<C-g>wb", "<cmd>GpWhisperPrepend<cr>", keymapOptions("Whisper Prepend (before) "))

vim.keymap.set("v", "<C-g>wr", ":<C-u>'<,'>GpWhisperRewrite<cr>", keymapOptions("Visual Whisper Rewrite"))
vim.keymap.set("v", "<C-g>wa", ":<C-u>'<,'>GpWhisperAppend<cr>", keymapOptions("Visual Whisper Append (after)"))
vim.keymap.set("v", "<C-g>wb", ":<C-u>'<,'>GpWhisperPrepend<cr>", keymapOptions("Visual Whisper Prepend (before)"))
-- }}}

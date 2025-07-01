return {
	{
		"zbirenbaum/copilot.lua",
		lazy = true,
		cmd = { "Copilot" },
		event = "InsertEnter",
		keys = {
			{ "<C-d>", mode = "i" },
			{ "<leader>cp", "<cmd>Copilot panel<cr>", desc = "open copilot side panel" },
			{
				"<leader>cc",
				function()
					require("copilot.suggestion").toggle_auto_trigger()
					print("Copilot enabled:", vim.b.copilot_suggestion_auto_trigger)
				end,
				desc = "toggle copilot",
			},
		},
		opts = {
			panel = {
				enabled = true,
				auto_refresh = true,
				layout = {
					position = "right", -- | top | left | right
				},
			},
			suggestion = {
				keymap = {
					accept = "<C-f>", -- like fish
					next = "<C-d>", -- also triggers when not on auto
					prev = "<C-s>",
				},
			},
		},
	},

	{
		"robitx/gp.nvim",
		event = "VeryLazy",
		config = function()
			local gp_chat_dir = os.getenv("HOME") .. "/Documents/gp-chats"
			require("gp").setup({
				openai_api_key = { "cat", vim.fn.stdpath("config") .. "/openai_api_key" },
				chat_dir = gp_chat_dir,
				chat_conceal_model_params = false,
				agents = {
					{ name = "ChatGPT4o-mini", disable = true },
					{
						provider = "openai",
						name = "CodeGPT4o",
						chat = true,
						command = false,
						model = { model = "gpt-4o" },
						system_prompt = "You are a helpful AI assistant",
					},
					{
						provider = "copilot",
						name = "ChatCopilot",
						chat = true,
						command = false,
						model = { model = "gpt-4o" },
						system_prompt = "You are a helpful AI assistant",
					},
				},
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

			vim.keymap.set(
				{ "n", "i" },
				"<C-g>wr",
				"<cmd>GpWhisperRewrite<cr>",
				keymapOptions("Whisper Inline Rewrite")
			)
			vim.keymap.set({ "n", "i" }, "<C-g>wa", "<cmd>GpWhisperAppend<cr>", keymapOptions("Whisper Append (after)"))
			vim.keymap.set(
				{ "n", "i" },
				"<C-g>wb",
				"<cmd>GpWhisperPrepend<cr>",
				keymapOptions("Whisper Prepend (before) ")
			)

			vim.keymap.set("v", "<C-g>wr", ":<C-u>'<,'>GpWhisperRewrite<cr>", keymapOptions("Visual Whisper Rewrite"))
			vim.keymap.set(
				"v",
				"<C-g>wa",
				":<C-u>'<,'>GpWhisperAppend<cr>",
				keymapOptions("Visual Whisper Append (after)")
			)
			vim.keymap.set(
				"v",
				"<C-g>wb",
				":<C-u>'<,'>GpWhisperPrepend<cr>",
				keymapOptions("Visual Whisper Prepend (before)")
			)
		end,
	},
}

-- Refactoring and AI plugins
return {
	-- GP.nvim for ChatGPT/Copilot chat
	{
		"robitx/gp.nvim",
		event = "VeryLazy",
		config = function()
			local gp_chat_dir = os.getenv("HOME") .. "/Documents/gp-chats"
			local get_secret_cmd = "cat ~/.config/github-copilot/apps.json | sed -e 's/.*oauth_token...//;s/\".*//'"
			require("gp").setup({
				chat_dir = gp_chat_dir,
				chat_conceal_model_params = false,
				providers = {
					openai = { disable = true },
					copilot = {
						-- disable = false,
						endpoint = "https://api.githubcopilot.com/chat/completions",
						secret = { "bash", "-c", get_secret_cmd },
					},
				},
				agents = {
					{ name = "CodeCopilot", disable = true },
					{ name = "CodeGPT-o3-mini", disable = true },
					{ name = "CodeGPT4o", disable = true },
					{ name = "CodeGPT4o-mini", disable = true },
					{
						provider = "copilot",
						name = "claude-sonnet-4",
						chat = true,
						command = false,
						model = { model = "claude-sonnet-4" },
						system_prompt = "You are an expert AI programming assistant",
					},
					{
						provider = "copilot",
						name = "gemini-2.5-pro",
						chat = true,
						command = false,
						model = { model = "gemini-2.5-pro" },
						system_prompt = "You are an expert AI programming assistant",
					},
					{
						provider = "copilot",
						name = "gpt-5",
						chat = true,
						command = false,
						model = { model = "gpt-5" },
						system_prompt = "You are an expert AI programming assistant",
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

	-- GitHub Copilot
	{
		"zbirenbaum/copilot.lua",
		lazy = true,
		cmd = { "Copilot" },
		event = "InsertEnter",
		keys = {
			{ "<C-d>", mode = "i" },
			{
				"<leader>cc",
				function()
					if require("copilot.client").is_disabled() then
						vim.cmd("Copilot enable")
						print("copilot enabled")
					else
						vim.cmd("Copilot disable")
						print("copilot disabled")
					end
				end,
				desc = "toggle copilot globally",
			},
		},
		config = function()
			require("copilot").setup({
				panel = {
					enabled = false,
				},
				suggestion = {
					keymap = {
						accept = "<C-f>", -- like fish
						next = "<C-d>", -- also triggers when not on auto
						prev = "<C-s>",
					},
				},
			})
			vim.cmd("Copilot disable") -- enable on demand
		end,
	},

	{
		"stevearc/quicker.nvim",
		ft = "qf",
		---@module "quicker"
		---@type quicker.SetupOptions
		opts = {},
	},
}

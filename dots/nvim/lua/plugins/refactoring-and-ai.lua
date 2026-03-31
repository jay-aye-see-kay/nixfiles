return {
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
		"folke/sidekick.nvim",
		opts = {
			nes = { enabled = false },
			cli = {
				mux = {
					backend = "tmux",
					enabled = true,
				},
			},
		},
		keys = {
			{
				",s",
				function()
					require("sidekick.cli").toggle({ name = "opencode", focus = true })
				end,
				desc = "Sidekick Toggle Opencode",
			},
		},
	},

	{
		"carlos-algms/agentic.nvim",
		config = function()
			require("agentic").setup({
				provider = "opencode-acp",
				headers = {
					input = function(parts)
						local usage = vim.t.agentic_usage
						local usage_str = ""
						if usage then
							local used_k = math.floor(usage.used / 1000)
							local size_k = math.floor(usage.size / 1000)
							local pct = math.floor((usage.used / usage.size) * 100)
							usage_str = string.format(" | %dk/%dk (%d%%)", used_k, size_k, pct)
						end
						return parts.title .. usage_str .. " | " .. parts.suffix
					end,
				},
				hooks = {
					on_session_update = function(data)
						if data.update.sessionUpdate == "usage_update" then
							if vim.api.nvim_tabpage_is_valid(data.tab_page_id) then
								vim.t[data.tab_page_id].agentic_usage = {
									used = data.update.used,
									size = data.update.size,
								}
								-- Trigger header re-render for input window
								for _, win in ipairs(vim.api.nvim_tabpage_list_wins(data.tab_page_id)) do
									local buf = vim.api.nvim_win_get_buf(win)
									if vim.bo[buf].filetype == "AgenticInput" then
										local WindowDecoration = require("agentic.ui.window_decoration")
										WindowDecoration.render_header(buf, "input")
										break
									end
								end
							end
						end
					end,
				},
			})
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "AgenticInput",
				callback = function()
					vim.keymap.set("n", "ZZ", "<Nop>", { buffer = true })
				end,
			})
		end,
		keys = {
			{
				"<C-\\>",
				function()
					require("agentic").toggle()
				end,
				mode = { "n", "v", "i" },
				desc = "Toggle Agentic Chat",
			},
			{
				"<C-'>", -- note: not currently working through tmux
				function()
					require("agentic").add_selection_or_file_to_context()
				end,
				mode = { "n", "v" },
				desc = "Add file or selection to Agentic to Context",
			},
			{
				"<leader>an",
				function()
					require("agentic").new_session()
				end,
				mode = { "n", "v" },
				desc = "New Agentic Session",
			},
			{
				"<leader>ar",
				function()
					require("agentic").restore_session()
				end,
				mode = { "n" },
				desc = "Agentic Sessions",
			},
			{
				"<leader>as",
				function()
					require("agentic").stop_generation()
				end,
				mode = { "n" },
				desc = "Agentic Stop",
			},
		},
	},

	{
		"stevearc/quicker.nvim",
		ft = "qf",
		---@module "quicker"
		---@type quicker.SetupOptions
		opts = {},
		keys = {
			{
				"<leader>q",
				function()
					require("quicker").toggle()
				end,
				desc = "Toggle quickfix",
			},
			{
				"<",
				function()
					require("quicker").collapse()
				end,
				ft = "qf",
				desc = "Collapse quickfix context",
			},
			{
				">",
				function()
					require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
				end,
				ft = "qf",
				desc = "Expand quickfix context",
			},
		},
	},
}

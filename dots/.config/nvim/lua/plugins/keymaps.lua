local h = require("config.helpers")

return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			local wk = require("which-key")
			wk.setup({
				plugins = {
					spelling = { enabled = true },
				},
			})

			-- Define helper functions
			local grep_notes = function()
				require("telescope.builtin").live_grep({ cwd = "$HOME/notes" })
			end

			local project_files = function()
				local ok = pcall(require("telescope.builtin").git_files)
				if not ok then
					require("telescope.builtin").find_files()
				end
			end

			local function mru_buffers()
				require("telescope.builtin").buffers({
					sort_mru = true,
					ignore_current_buffer = true,
				})
			end

			local function cwd_mru_buffers()
				require("telescope.builtin").buffers({
					sort_mru = true,
					ignore_current_buffer = true,
				})
			end

			-- Quick keymaps with comma prefix
			wk.add({ { ",", group = "quick keymaps" } })
			h.keymap("n", ",b", mru_buffers, "🔭 buffers")
			h.keymap("n", ",B", cwd_mru_buffers, "🔭 buffers (cwd only)")
			h.keymap("n", ",l", "<cmd>Telescope current_buffer_fuzzy_find<cr>", "🔭 buffer lines")
			h.keymap("n", ",f", "<cmd>Telescope find_files<cr>", "🔭 files")
			h.keymap("n", ",o", "<cmd>Telescope oldfiles<cr>", "🔭 oldfiles")
			h.keymap("n", ",.", "<cmd>Neotree reveal current<cr>", "File explorer in place")

			-- LSP keymaps
			wk.add({ { "<leader>l", group = "+lsp" } })
			h.keymap("n", "<leader>la", vim.lsp.buf.code_action, "Code action")
			h.keymap("n", "<leader>lr", vim.lsp.buf.rename, "Rename symbol")
			h.keymap("n", "<leader>ld", "<cmd>Telescope lsp_document_diagnostics<cr>", "Document diagnostics")
			h.keymap("n", "<leader>lD", "<cmd>Telescope lsp_workspace_diagnostics<cr>", "Workspace diagnostics")
			h.keymap("n", "<leader>lt", "<cmd>TroubleToggle<cr>", "Toggle Trouble")
			h.keymap("n", "<leader>li", "<cmd>LspInfo<cr>", "LSP Info")
			h.keymap("n", "<leader>lf", vim.lsp.buf.format, "Format buffer")

			-- Finder keymaps
			wk.add({ { "<leader>f", group = "+find" } })
			h.keymap("n", "<leader>fb", mru_buffers, "🔭 buffers")
			h.keymap("n", "<leader>fB", cwd_mru_buffers, "🔭 buffers (cwd only)")
			h.keymap("n", "<leader>ff", "<cmd>Telescope find_files<cr>", "🔭 files")
			h.keymap("n", "<leader>fg", project_files, "🔭 git files")
			h.keymap("n", "<leader>fh", function()
				require("telescope.builtin").help_tags({ default_text = vim.fn.expand("<cword>") })
			end, "🔭 help tags")
			h.keymap("n", "<leader>fc", "<cmd>Telescope commands<cr>", "🔭 commands")
			h.keymap("n", "<leader>fo", "<cmd>Telescope oldfiles<cr>", "🔭 oldfiles")
			h.keymap("n", "<leader>fl", "<cmd>Telescope current_buffer_fuzzy_find<cr>", "🔭 buffer lines")
			h.keymap("n", "<leader>fw", "<cmd>Telescope spell_suggest<cr>", "🔭 spelling")
			h.keymap("n", "<leader>fu", "<cmd>Telescope grep_string<cr>", "🔭 word under cursor")
			h.keymap("n", "<leader>fn", grep_notes, "🔭 search notes")

			wk.add({ { "<leader>fi", group = "+in" } })
			h.keymap("n", "<leader>fio", function()
				require("telescope.builtin").live_grep({ grep_open_files = true })
			end, "🔭 in open buffers")

			-- Git keymaps with directed maps
			wk.add({ { "<leader>g", group = "+git" } })
			h.make_directed_maps("<leader>g", "Git Status", "Gedit :")
			h.keymap("n", "<leader>gg", "<Cmd>Telescope git_commits<CR>", "🔭 commits")
			h.keymap("n", "<leader>gc", "<Cmd>Telescope git_bcommits<CR>", "🔭 buffer commits")
			h.keymap("n", "<leader>gb", "<Cmd>Telescope git_branches<CR>", "🔭 branches")

			-- Terminal keymaps with directed maps
			wk.add({ { "<leader>t", group = "+terminal" } })
			h.make_directed_maps("<leader>t", "New terminal", "terminal")

			-- File explorer keymaps with directed maps
			wk.add({ { "<leader>e", group = "+file explorer" } })
			h.make_directed_maps("<leader>e", "File explorer", "Neotree reveal current")
			h.keymap("n", "<leader>ee", "<cmd>Neotree toggle<cr>", "Toggle file tree")

			-- Notes keymaps with directed maps
			wk.add({
				{ "<leader>n", group = "+notes" },
				{ "<leader>ny", group = "+yesterday" },
				{ "<leader>nt", group = "+tomorrow" },
			})
			h.make_directed_maps("<leader>n", "Today's notepad", "LogbookToday")
			h.keymap("n", "<leader>nf", grep_notes, "🔭 search notes")
			h.make_directed_maps("<leader>ny", "Yesterday's notepad", "LogbookYesterday")
			h.make_directed_maps("<leader>nt", "Tomorrow's notepad", "LogbookTomorrow")

			-- Misc keymaps
			wk.add({ { "<leader>m", group = "+misc" } })
			h.keymap("n", "<leader>mp", function()
				vim.api.nvim_win_set_width(0, 60)
				vim.api.nvim_win_set_option(0, "winfixwidth", true)
			end, "Pin window to edge")
			h.keymap("n", "<leader>mP", function()
				vim.api.nvim_win_set_option(0, "winfixwidth", false)
			end, "Unpin window")

			vim.opt.timeoutlen = 250
		end,
	},

	-- Hydra for sticky keymaps
	{
		"nvimtools/hydra.nvim",
		event = "VeryLazy",
		config = function()
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
		end,
	},
}

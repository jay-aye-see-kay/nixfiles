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
					only_cwd = true,
				})
			end

			-- Quick keymaps with comma prefix
			wk.add({ { ",", group = "quick keymaps" } })
			vim.keymap.set("n", ",a", "<cmd>Telescope live_grep<cr>", { desc = "🔭 live grep" })
			vim.keymap.set("n", ",b", mru_buffers, { desc = "🔭 buffers" })
			vim.keymap.set("n", ",B", cwd_mru_buffers, { desc = "🔭 buffers (cwd only)" })
			vim.keymap.set("n", ",l", "<cmd>Telescope current_buffer_fuzzy_find<cr>", { desc = "🔭 buffer lines" })
			vim.keymap.set("n", ",f", "<cmd>Telescope find_files<cr>", { desc = "🔭 files" })
			vim.keymap.set("n", ",o", "<cmd>Telescope oldfiles<cr>", { desc = "🔭 oldfiles" })
			vim.keymap.set("n", ",.", "<cmd>Neotree reveal current<cr>", { desc = "File explorer in place" })

			-- LSP keymaps
			wk.add({ { "<leader>l", group = "+lsp" } })
			vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, { desc = "Code action" })
			vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, { desc = "Rename symbol" })
			vim.keymap.set("n", "<leader>ld", "<cmd>Telescope lsp_document_diagnostics<cr>", { desc = "Document diagnostics" })
			vim.keymap.set("n", "<leader>lD", "<cmd>Telescope lsp_workspace_diagnostics<cr>", { desc = "Workspace diagnostics" })
			vim.keymap.set("n", "<leader>lt", "<cmd>TroubleToggle<cr>", { desc = "Toggle Trouble" })
			vim.keymap.set("n", "<leader>li", "<cmd>LspInfo<cr>", { desc = "LSP Info" })
			vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format, { desc = "Format buffer" })

			-- Finder keymaps
			wk.add({ { "<leader>f", group = "+find" } })
			vim.keymap.set("n", "<leader>ff", "<cmd>Telescope live_grep<cr>", { desc = "🔭 live grep" })
			vim.keymap.set("n", "<leader>fb", mru_buffers, { desc = "🔭 buffers" })
			vim.keymap.set("n", "<leader>fB", cwd_mru_buffers, { desc = "🔭 buffers (cwd only)" })
			vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "🔭 files" })
			vim.keymap.set("n", "<leader>fg", project_files, { desc = "🔭 git files" })
			vim.keymap.set("n", "<leader>fh", function()
				require("telescope.builtin").help_tags({ default_text = vim.fn.expand("<cword>") })
			end, { desc = "🔭 help tags" })
			vim.keymap.set("n", "<leader>fc", "<cmd>Telescope commands<cr>", { desc = "🔭 commands" })
			vim.keymap.set("n", "<leader>fo", "<cmd>Telescope oldfiles<cr>", { desc = "🔭 oldfiles" })
			vim.keymap.set("n", "<leader>fl", "<cmd>Telescope current_buffer_fuzzy_find<cr>", { desc = "🔭 buffer lines" })
			vim.keymap.set("n", "<leader>fw", "<cmd>Telescope spell_suggest<cr>", { desc = "🔭 spelling" })
			vim.keymap.set("n", "<leader>fu", "<cmd>Telescope grep_string<cr>", { desc = "🔭 word under cursor" })
			vim.keymap.set("n", "<leader>fn", grep_notes, { desc = "🔭 search notes" })

			wk.add({ { "<leader>fi", group = "+in" } })
			vim.keymap.set("n", "<leader>fio", function()
				require("telescope.builtin").live_grep({ grep_open_files = true })
			end, { desc = "🔭 in open buffers" })

			-- Git keymaps with directed maps
			wk.add({ { "<leader>g", group = "+git" } })
			h.make_directed_maps("<leader>g", "Git Status", "Gedit :")
			vim.keymap.set("n", "<leader>gg", "<Cmd>Telescope git_commits<CR>", { desc = "🔭 commits" })
			vim.keymap.set("n", "<leader>gc", "<Cmd>Telescope git_bcommits<CR>", { desc = "🔭 buffer commits" })
			vim.keymap.set("n", "<leader>gb", "<Cmd>Telescope git_branches<CR>", { desc = "🔭 branches" })

			-- Terminal keymaps with directed maps
			wk.add({ { "<leader>t", group = "+terminal" } })
			h.make_directed_maps("<leader>t", "New terminal", "terminal")

			-- File explorer keymaps with directed maps
			wk.add({ { "<leader>e", group = "+file explorer" } })
			h.make_directed_maps("<leader>e", "File explorer", "Neotree reveal current")
			vim.keymap.set("n", "<leader>ee", "<cmd>Neotree toggle<cr>", { desc = "Toggle file tree" })

			-- Notes keymaps with directed maps
			wk.add({
				{ "<leader>n", group = "+notes" },
				{ "<leader>ny", group = "+yesterday" },
				{ "<leader>nt", group = "+tomorrow" },
			})
			h.make_directed_maps("<leader>n", "Today's notepad", "LogbookToday")
			vim.keymap.set("n", "<leader>nf", grep_notes, { desc = "🔭 search notes" })
			h.make_directed_maps("<leader>ny", "Yesterday's notepad", "LogbookYesterday")
			h.make_directed_maps("<leader>nt", "Tomorrow's notepad", "LogbookTomorrow")

			-- Misc keymaps
			wk.add({ { "<leader>m", group = "+misc" } })
			vim.keymap.set("n", "<leader>mp", function()
				vim.api.nvim_win_set_width(0, 60)
				vim.wo.winfixwidth = true
			end, { desc = "Pin window to edge" })
			vim.keymap.set("n", "<leader>mP", function()
				vim.wo.winfixwidth = false
			end, { desc = "Unpin window" })
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

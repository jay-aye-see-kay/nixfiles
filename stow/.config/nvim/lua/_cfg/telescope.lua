-- Telescope and extensions
-- Keymaps defined after plugins
return {
	-- Telescope extensions (dependencies)
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		lazy = true,
		build = "make",
	},
	{
		"nvim-telescope/telescope-live-grep-args.nvim",
		lazy = true,
	},
	{
		"debugloop/telescope-undo.nvim",
		lazy = true,
	},
	{
		"jvgrootveld/telescope-zoxide",
		lazy = true,
	},

	-- Main telescope plugin
	{
		"nvim-telescope/telescope.nvim",
		lazy = true,
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-fzf-native.nvim",
			"nvim-telescope/telescope-live-grep-args.nvim",
			"debugloop/telescope-undo.nvim",
			"jvgrootveld/telescope-zoxide",
		},
		config = function()
			local actions = require("telescope.actions")
			local action_layout = require("telescope.actions.layout")
			local telescope = require("telescope")
			local lga_actions = require("telescope-live-grep-args.actions")

			telescope.setup({
				defaults = {
					layout_config = { prompt_position = "top" },
					sorting_strategy = "ascending",
					layout_strategy = "flex",
					dynamic_preview_title = true,
					file_ignore_patterns = { ".git/" },
					mappings = {
						i = {
							["<C-g>"] = action_layout.toggle_preview,
							["<C-x>"] = false,
							["<C-s>"] = actions.select_horizontal,
							["<C-l>"] = actions.cycle_history_next,
							["<C-h>"] = actions.cycle_history_prev,
						},
					},
				},
				pickers = {
					buffers = {
						mappings = {
							i = {
								["<C-x>"] = actions.delete_buffer,
							},
						},
					},
				},
				extensions = {
					fzf = {
						fuzzy = true,
						override_generic_sorter = true,
						override_file_sorter = true,
					},
					undo = {
						use_delta = false,
					},
					zoxide = {
						mappings = {
							["<c-b>"] = nil,
							["<c-t>"] = nil,
							default = {
								action = function(selection)
									vim.cmd.tabedit(selection.path)
									vim.cmd.tcd(selection.path)
								end,
							},
						},
					},
					live_grep_args = {
						auto_quoting = true,
						mappings = {
							i = {
								["<C-k>"] = lga_actions.quote_prompt(),
								["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
							},
						},
					},
				},
			})
			telescope.load_extension("fzf")
			telescope.load_extension("undo")
			telescope.load_extension("zoxide")
			telescope.load_extension("live_grep_args")
		end,
		keys = {
			{ "<leader>fU", "<cmd>Telescope undo undo<cr>", desc = "search telescope history" },
			{ "<leader>fz", "<cmd>Telescope zoxide list<cr>", desc = "cd with zoxide" },
			{ ",z", "<cmd>Telescope zoxide list<cr>", desc = "cd with zoxide" },
			{
				"<leader>fa",
				"<cmd>Telescope live_grep_args live_grep_args<cr>",
				desc = "🔭 full text search",
			},
		},
	},
}

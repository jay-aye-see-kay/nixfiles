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
			"jvgrootveld/telescope-zoxide",
		},
		config = function()
			local actions = require("telescope.actions")
			local action_layout = require("telescope.actions.layout")
			local telescope = require("telescope")

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
					zoxide = {
						mappings = {
							["<c-b>"] = nil,
							["<c-t>"] = nil,
							default = {
								action = function(selection)
									-- open a fresh tab with a fyler tree for the project. don't
									-- `tabedit` the directory: fyler's dir-buffer hijack is unreliable
									-- here (the new tab can collapse when a finder for the path is
									-- already open elsewhere)
									vim.cmd("tabnew")
									vim.cmd.tcd(selection.path)
									require("fyler").open({ kind = "replace", root_path = selection.path })
								end,
							},
						},
					},
				},
			})
			telescope.load_extension("fzf")
			telescope.load_extension("zoxide")
		end,
		keys = {
			{ "<leader>fz", "<cmd>Telescope zoxide list<cr>", desc = "cd with zoxide" },
			{ ",z", "<cmd>Telescope zoxide list<cr>", desc = "cd with zoxide" },
		},
	},
}

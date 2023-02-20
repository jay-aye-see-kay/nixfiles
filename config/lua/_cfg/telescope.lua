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
				["<esc>"] = actions.close,
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
				default = {
					action = function(selection)
						vim.cmd("cd " .. selection.path)
						require("telescope.builtin").find_files()
					end,
				},
			},
		},
	},
})
telescope.load_extension("fzf")
telescope.load_extension("undo")
telescope.load_extension("zoxide")

vim.keymap.set("n", "<leader>fU", telescope.extensions.undo.undo, { desc = "search telescope history" })
vim.keymap.set("n", "<leader>fz", telescope.extensions.zoxide.list, { desc = "cd with zoxide" })
vim.keymap.set("n", ",z", telescope.extensions.zoxide.list, { desc = "cd with zoxide" })

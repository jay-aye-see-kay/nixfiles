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
telescope.load_extension("advanced_git_search")

vim.keymap.set("n", "<leader>fU", telescope.extensions.undo.undo, { desc = "search telescope history" })
vim.keymap.set("n", "<leader>fz", telescope.extensions.zoxide.list, { desc = "cd with zoxide" })
vim.keymap.set("n", ",z", telescope.extensions.zoxide.list, { desc = "cd with zoxide" })

vim.keymap.set(
	"n",
	"<leader>fa",
	telescope.extensions.live_grep_args.live_grep_args,
	{ desc = "🔭 full text search" }
)
vim.keymap.set(
	"n",
	"<leader>fG",
	telescope.extensions.advanced_git_search.search_log_content,
	{ desc = "🔭 search git commit lines" }
)

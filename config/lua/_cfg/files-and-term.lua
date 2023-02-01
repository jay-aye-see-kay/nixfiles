local h = require("_cfg.helpers")

-- file tree {{{
vim.g.neo_tree_remove_legacy_commands = 1

require("neo-tree").setup({
	window = {
		position = "left",
		width = 30,
		mappings = {
			["<space>"] = false,
			["l"] = "open",
			["h"] = "close_node",
		},
	},
	filesystem = {
		filtered_items = {
			visible = true,
			hide_dotfiles = false,
		},
		hijack_netrw_behavior = "open_current",
		use_libuv_file_watcher = true,
		follow_current_file = true,
		window = {
			mappings = {
				["H"] = "navigate_up",
				["L"] = "set_root",
				["."] = "toggle_hidden",
				["/"] = "fuzzy_finder",
				["D"] = "fuzzy_finder_directory",
				["<c-x>"] = "clear_filter",
				["[g"] = "prev_git_modified",
				["]g"] = "next_git_modified",
			},
		},
	},
})

require("window-picker").setup()

-- window jumper/picker, used by neotree, but might be cool on it's own?
vim.keymap.set("n", "<leader>j", function()
	local picked_window_id = require("window-picker").pick_window()
	if picked_window_id then
		vim.api.nvim_set_current_win(picked_window_id)
	end
end, { desc = "Pick a window" })
-- }}}
-- {{{ terminal
vim.keymap.set("t", "<ESC>", [[<C-\><C-n>]])

h.autocmd({ "TermOpen" }, {
	callback = function()
		-- stops terminal side scrolling
		vim.cmd([[ setlocal nonumber norelativenumber signcolumn=no ]])
		-- ctrl-c, ctrl-p, ctrl-n, enter should all be passed through from normal mode
		vim.keymap.set("n", "<C-c>", [[ i<C-c><C-\><C-n> ]], { buffer = 0 })
		vim.keymap.set("n", "<C-n>", [[ i<C-n><C-\><C-n> ]], { buffer = 0 })
		vim.keymap.set("n", "<C-p>", [[ i<C-p><C-\><C-n> ]], { buffer = 0 })
		vim.keymap.set("n", "<CR>", [[ i<CR><C-\><C-n> ]], { buffer = 0 })
	end,
})
-- }}}

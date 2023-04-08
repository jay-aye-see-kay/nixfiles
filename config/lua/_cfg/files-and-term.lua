local h = require("_cfg.helpers")

-- file tree {{{
vim.g.neo_tree_remove_legacy_commands = 1

require("neo-tree").setup({
	window = {
		position = "left",
		width = 30,
		mappings = {
			["<space>"] = false,
			["z"] = false,
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
				["/"] = false,
				["D"] = "fuzzy_finder_directory",
				["<c-x>"] = "clear_filter",
				["[g"] = "prev_git_modified",
				["]g"] = "next_git_modified",
				["a"] = { "add", config = { show_path = "relative" } },
				["c"] = { "copy", config = { show_path = "relative" } },
				["m"] = { "move", config = { show_path = "relative" } },
			},
		},
	},
})
-- }}}

-- {{{ terminal
vim.keymap.set("t", "<ESC>", [[<C-\><C-n>]])

h.autocmd({ "TermEnter" }, {
	command = "setlocal winhighlight=Normal:ActiveTerm",
})
h.autocmd({ "TermLeave" }, {
	command = "setlocal winhighlight=Normal:NC",
})
vim.cmd("highlight ActiveTerm guibg=#22262E")

h.autocmd({ "TermOpen" }, {
	callback = function()
		-- stops terminal side scrolling
		vim.cmd([[ setlocal nonumber norelativenumber signcolumn=no ]])
		-- put this back to default
		vim.opt.scrolloff = 0
		vim.opt.sidescrolloff = 0
		-- ctrl-c, ctrl-p, ctrl-n, enter should all be passed through from normal mode
		vim.keymap.set("n", "<C-c>", [[ i<C-c><C-\><C-n> ]], { buffer = 0 })
		vim.keymap.set("n", "<C-n>", [[ i<C-n><C-\><C-n> ]], { buffer = 0 })
		vim.keymap.set("n", "<C-p>", [[ i<C-p><C-\><C-n> ]], { buffer = 0 })
		vim.keymap.set("n", "<CR>", [[ i<CR><C-\><C-n> ]], { buffer = 0 })
	end,
})
-- }}}

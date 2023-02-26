-- must be first
require("mini.basics").setup({
	options = {
		basic = true, -- Basic options ('termguicolors', 'number', 'ignorecase', and many more)
		extra_ui = false, -- Extra UI features ('winblend', 'cmdheight=0', ...)
		win_borders = "bold", -- Presets for window borders ('single', 'double', ...)
	},
	mappings = {
		basic = true, -- Basic mappings (better 'jk', save with Ctrl+S, ...)
		windows = true, -- Window navigation with <C-hjkl>, resize with <C-arrow>
		option_toggle_prefix = [[\]],
		move_with_alt = false,
	},
	autocommands = {
		basic = false,
		relnum_in_visual_mode = false,
	},
})

require("mini.ai").setup()
require("mini.starter").setup()
require("mini.align").setup({
	mappings = {
		start = "gl",
		start_with_preview = "gL",
	},
})

require("mini.misc").setup_restore_cursor()

vim.keymap.set("n", "<c-w>z", require("mini.misc").zoom)
vim.keymap.set("n", "<c-w><c-z>", require("mini.misc").zoom)

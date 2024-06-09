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

-- change mini.basics new blank line keymaps to match unimpaired's
vim.keymap.del("n", "go")
vim.keymap.del("n", "gO")
local empty_line = {
	above = "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>",
	below = "<Cmd>call append(line('.'),     repeat([''], v:count1))<CR>",
}
vim.keymap.set("n", "] ", empty_line.below, { desc = "Put empty line below" })
vim.keymap.set("n", "[ ", empty_line.above, { desc = "Put empty line above" })

require("mini.ai").setup()
require("mini.align").setup({
	mappings = {
		start = "gl",
		start_with_preview = "gL",
	},
})

require("mini.misc").setup_restore_cursor()

vim.keymap.set("n", "<c-w>z", require("mini.misc").zoom)
vim.keymap.set("n", "<c-w><c-z>", require("mini.misc").zoom)

vim.g.miniindentscope_disable = true
vim.keymap.set("n", "\\I", function()
	vim.g.miniindentscope_disable = not vim.g.miniindentscope_disable
end, { desc = "toggle indentscope" })
require("mini.indentscope").setup()

require("mini.move").setup({
	mappings = {
		left = "",
		right = "",
		line_left = "",
		line_right = "",
		down = "]e",
		up = "[e",
		line_down = "]e",
		line_up = "[e",
	},
})

require("mini.bracketed").setup({
	comment = { suffix = "c" },
	diagnostic = { suffix = "d" },
	file = { suffix = "f" },
	quickfix = { suffix = "q" },
	-- disabled keymaps
	buffer = { suffix = "" },
	conflict = { suffix = "" },
	indent = { suffix = "" },
	jump = { suffix = "" },
	location = { suffix = "" },
	oldfile = { suffix = "" },
	treesitter = { suffix = "" },
	undo = { suffix = "" },
	window = { suffix = "" },
	yank = { suffix = "" },
})

require("mini.bufremove").setup()

vim.keymap.set("n", "<leader>bd", function()
	require("mini.bufremove").delete()
end)

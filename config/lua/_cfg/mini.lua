-- must be first
require("mini.basics").setup()

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

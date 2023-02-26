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

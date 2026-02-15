-- Load core settings before plugins
require("config.core")

-- tree sitter and blink.cmp managed without lazy
require("config.treesitter")
require("config.completions")

-- Setup lazy.nvim - automatically imports all modules from lua/plugins/
require("lazy").setup("plugins", {
	change_detection = {
		enabled = false,
		notify = false,
	},
	ui = { border = "rounded" },
	performance = {
		reset_packpath = false,
		rtp = {
			reset = false,
			disabled_plugins = { "tohtml", "tutor" },
		},
	},
})

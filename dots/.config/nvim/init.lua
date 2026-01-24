-- Load core settings before plugins
require("config.core")

-- tree sitter managed without lazy
require("config.treesitter")

-- Setup lazy.nvim - automatically imports all modules from lua/plugins/
require("lazy").setup("plugins", {
	change_detection = {
		enabled = false,
		notify = false,
	},
	ui = { border = "rounded" },
	performance = {
		rtp = {
			disabled_plugins = { "tohtml", "tutor" },
		},
	},
})

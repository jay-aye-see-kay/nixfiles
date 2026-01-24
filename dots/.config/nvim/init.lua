-- Load core settings before plugins
require("config.core")

-- Setup lazy.nvim - automatically imports all modules from lua/plugins/
require("lazy").setup("plugins", {
	ui = { border = "rounded" },
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})

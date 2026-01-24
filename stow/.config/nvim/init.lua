-- Load core settings before plugins
require("_cfg.core")

-- Setup lazy.nvim with plugin specs from _cfg modules
require("lazy").setup({
	{ import = "_cfg.colorscheme" },
	{ import = "_cfg.debugging" },
	{ import = "_cfg.files-and-term" },
	{ import = "_cfg.formatting" },
	{ import = "_cfg.git" },
	{ import = "_cfg.lines-and-bars" },
	{ import = "_cfg.mini" },
	{ import = "_cfg.misc" },
	{ import = "_cfg.notes" },
	{ import = "_cfg.refactoring-and-ai" },
	{ import = "_cfg.telescope" },
	{ import = "_cfg.treesitter" },
}, {
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

-- Load remaining config after lazy
require("_cfg.keymaps")
require("_cfg.lsp")
require("_cfg.snippets")

local h = require("_cfg.helpers")
h.bootstrap_lazy() -- init plugin manager

require("_cfg.core")

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		-- import your plugins
		{ import = "plugins" },

		-- TEMP
		{ "folke/neodev.nvim", opts = {}, lazy = false },
		{
			"pmizio/typescript-tools.nvim",
			dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
			opts = {},
			lazy = false,
		},
		{ "neovim/nvim-lspconfig", lazy = false },
		{ "hrsh7th/cmp-nvim-lsp", lazy = false },
		{ "hrsh7th/nvim-cmp", lazy = false },
	},
	-- Configure any other settings here. See the documentation for more details.
	-- colorscheme that will be used when installing plugins.
	install = { colorscheme = { "catppuccin-macchiato" } },
	-- automatically check for plugin updates
	checker = { enabled = true },
})

-- TODO migrate these to setup the normal lazy way
require("_cfg.rehome")

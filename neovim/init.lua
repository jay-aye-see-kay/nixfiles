local plugins = require("nln").plugins

require("_cfg.filetype")

plugins["outline.nvim"] = {
	lazy = true,
	cmd = { "Outline", "OutlineOpen" },
	opts = {},
}

plugins["leap.nvim"] = {
	config = function()
		require("leap").create_default_mappings()
	end,
}

--
-- TODO put lazy config above here, must setup plugin spec before calling lazy.setup
--
require("lazy").setup(plugins:for_lazy(), {
	dev = {
		path = require("nln").lazyPath,
		patterns = { "." },
		fallback = false,
	},
	performance = {
		reset_packpath = false,
		rtp = {
			reset = false,
		},
	},
})

--
-- old config below lazy
--

-- must be first as these setup leader keys
require("_cfg.mini")
require("_cfg.core")

require("_cfg.debugging")
require("_cfg.files-and-term")
require("_cfg.git")
require("_cfg.keymaps")
require("_cfg.lsp")
require("_cfg.notes")
require("_cfg.snippets")
require("_cfg.telescope")
require("_cfg.treesitter-and-refactoring")

-- temp: moved these here from flake.nix as not supported there anymore
require("nvim-surround").setup()
require("Comment").setup()
vim.g.skip_ts_context_commentstring_module = true
require("nvim-ts-autotag").setup()

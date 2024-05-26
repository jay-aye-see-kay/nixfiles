local plugins = require("nln").plugins

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

--
-- old config above this, new below
-- slowly migrating to lazy an package manager
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

local plugins = require("nln").plugins

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("_cfg.debugging")
require("_cfg.filetype")
require("_cfg.git")
require("_cfg.lines-and-bars")
require("_cfg.mini")
require("_cfg.treesitter")

plugins["outline.nvim"] = {
	lazy = true,
	cmd = { "Outline", "OutlineOpen" },
	opts = {},
	keys = {
		{ "<leader>o", "<cmd>Outline!<cr>", desc = "toggle outline" },
	},
}

plugins["leap.nvim"] = {
	config = function()
		require("leap").create_default_mappings()
	end,
}

plugins["nvim-ts-autotag"] = {
	event = "VeryLazy",
	opts = {},
}

plugins["nvim-ts-context-commentstring"] = {
	init = function()
		vim.g.skip_ts_context_commentstring_module = true
	end,
}
plugins["comment.nvim"] = {
	config = function()
		require("Comment").setup({
			pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
		})
	end,
}

plugins["nvim-surround"] = { event = "VeryLazy", opts = {} }

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

require("_cfg.core")

require("_cfg.files-and-term")
require("_cfg.keymaps")
require("_cfg.lsp")
require("_cfg.notes")
require("_cfg.snippets")
require("_cfg.telescope")
require("_cfg.refactoring-and-ai")

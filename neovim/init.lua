local plugins = require("nln").plugins

require("_cfg.core")

require("_cfg.colorscheme")
require("_cfg.debugging")
require("_cfg.files-and-term")
require("_cfg.git")
require("_cfg.lines-and-bars")
require("_cfg.mini")
require("_cfg.misc")
require("_cfg.notes")
require("_cfg.refactoring-and-ai")
require("_cfg.telescope")
require("_cfg.treesitter")

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

require("_cfg.keymaps")
require("_cfg.lsp")
require("_cfg.snippets")

-- debug command that prints all plugins (show prob be part of nln)
vim.api.nvim_create_user_command("ListPlugins", function(opts)
	for key, _ in pairs(require("nln").plugins) do
		if opts.args and key:find(opts.args) then
			print(key)
		end
	end
end, { nargs = "?" })

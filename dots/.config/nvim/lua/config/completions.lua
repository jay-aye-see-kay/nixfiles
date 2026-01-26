-- blink loaded from nix (no lazy.nvim)
require("blink.cmp").setup({
	completion = {
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 500,
		},
	},
	sources = {
		default = { "lsp", "path", "snippets", "buffer", "emoji" },
		providers = {
			emoji = {
				module = "blink-emoji",
				opts = {
					insert = true,
					trigger = function()
						return { ":" }
					end,
				},
			},
		},
	},
})

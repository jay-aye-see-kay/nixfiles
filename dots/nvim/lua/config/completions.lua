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
	keymap = {
		preset = "default",
		["<c-l>"] = { "snippet_forward" },
		["<c-h>"] = { "snippet_backward" },
		["<c-j>"] = {
			function(cmp)
				local word = cmp.get_context().get_keyword()
				for index, item in ipairs(cmp.get_items()) do
					if item.source_id == "snippets" and item.label == word then
						cmp.select_and_accept({ index = index })
					end
				end
			end,
		},
	},
})

local plugins = require("nln").plugins
local h = require("_cfg.helpers")

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

plugins["hover.nvim"] = {
	lazy = true,
	config = function()
		require("hover").setup({
			init = function()
				require("hover.providers.lsp")
				require("hover.providers.gh")
				require("hover.providers.gh_user")
				require("hover.providers.jira")
				require("hover.providers.man")
				require("hover.providers.dictionary")
			end,
			preview_opts = {
				border = nil,
			},
			-- Whether the contents of a currently open hover window should be moved
			-- to a :h preview-window when pressing the hover keymap.
			preview_window = true,
			title = true,
		})
	end,
	keys = {
		{
			"gK",
			function()
				require("hover").hover_select()
			end,
			desc = "hover.nvim (select)",
		},
	},
}

plugins["undotree"] = {
	lazy = true,
	keys = {
		{ "\\u", "<cmd>UndotreeToggle<cr>", desc = "Toggle undotree" },
	},
}

-- {{{ switching text-case (replaced abolish)
plugins["text-case.nvim"] = {
	dependencies = { "telescope.nvim" },
	config = function()
		local textcase = require("textcase")
		textcase.setup({ prefix = "ga" })
		textcase.register_keybindings("ga", textcase.api.to_dash_case, {
			prefix = "ga",
			quick_replace = "k",
			operator = "ok",
			lsp_rename = "K",
		})
		require("telescope").load_extension("textcase")
	end,
	keys = {
		"ga",
		{ "ga.", "<cmd>TextCaseOpenTelescope<CR>", mode = { "n", "x" }, desc = "Telescope" },
	},
	cmd = {
		"Subs",
		"TextCaseOpenTelescope",
		"TextCaseOpenTelescopeQuickChange",
		"TextCaseOpenTelescopeLSPChange",
		"TextCaseStartReplacingCommand",
	},
}

plugins["decisive.nvim"] = {
	lazy = true,
	ft = { "csv" },
	keys = {
		{ "\\v", ":lua require('decisive').align_csv({})<cr>", desc = "Align CSV" },
	},
}

local plugins = require("nln").plugins

plugins["conform.nvim"] = {
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },

	keys = {
		{
			"\\f",
			function()
				if vim.b.disable_autoformat then
					vim.b.disable_autoformat = false
					vim.notify("format-on-save enabled for BUFFER", vim.log.levels.INFO)
				else
					vim.b.disable_autoformat = true
					vim.notify("format-on-save disabled for BUFFER", vim.log.levels.INFO)
				end
			end,
			desc = "toggle buffer format-on-save",
		},
		{
			"\\F",
			function()
				if vim.g.disable_autoformat then
					vim.g.disable_autoformat = false
					vim.notify("format-on-save enabled for GLOBAL", vim.log.levels.INFO)
				else
					vim.g.disable_autoformat = true
					vim.notify("format-on-save disabled for GLOBAL", vim.log.levels.INFO)
				end
			end,
			desc = "toggle global format-on-save",
		},
	},

	---@module "conform"
	---@type conform.setupOpts
	opts = {
		formatters_by_ft = {
			javascript = { "prettierd", "prettier", stop_after_first = true },
			lua = { "stylua" },
			nix = { "nixpkgs_fmt" },
			python = { "isort", "black" },
		},

		default_format_opts = {
			lsp_format = "fallback",
		},

		format_on_save = function(bufnr)
			-- Disable autoformat on certain filetypes
			local ignore_filetypes = { "json", "yaml" }
			if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
				return
			end
			-- Disable with a global or buffer-local variable
			if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
				return
			end
			return { timeout_ms = 500, lsp_format = "fallback" }
		end,
	},

	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}

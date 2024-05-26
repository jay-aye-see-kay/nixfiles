-- lsp {{{
local lsp_servers = {
	"bashls",
	"cssls",
	"dockerls",
	"gopls",
	"html",
	"jsonls",
	"lua_ls",
	"nil_ls",
	"pyright",
	"rust_analyzer",
	"solargraph",
	"tailwindcss",
	"terraformls",
	"vimls",
	"yamlls",
}

require("neodev").setup({
	override = function(root_dir, library)
		if require("neodev.util").has_file(root_dir, "~/code/neovim-flake") then
			library.enabled = true
			library.plugins = true
		end
	end,
})

local lsp_augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local function on_attach(client, bufnr)
	if client.server_capabilities.documentSymbolProvider then
		require("nvim-navic").attach(client, bufnr)
	end
	-- autoformat document with null-ls if setup
	if client.supports_method("textDocument/formatting") then
		vim.api.nvim_clear_autocmds({ group = lsp_augroup, buffer = bufnr })
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = lsp_augroup,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.format({
					bufnr = bufnr,
					filter = function(fmt_client)
						return fmt_client.name == "null-ls"
					end,
				})
			end,
		})
	end
end

local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("typescript").setup({
	server = {
		on_attach = on_attach,
		capabilities = capabilities,
	},
})

for _, lsp in pairs(lsp_servers) do
	local settings = {}
	if lsp == "jsonls" then
		settings.json = {
			validate = { enable = true },
			schemas = require("schemastore").json.schemas(),
		}
	elseif lsp == "yamlls" then
		settings = {
			yaml = {
				schemas = require("schemastore").yaml.schemas(),
			},
		}
	elseif lsp == "lua_ls" then
		settings.Lua = {
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim" } },
			workspace = { checkThirdParty = false },
			telemetry = { enable = false },
		}
	end

	require("lspconfig")[lsp].setup({
		settings = settings,
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
	border = "rounded",
})

-- @param severity "ERROR"| "WARN"| "INFO"| "HINT"
local force_diagnostic_severity = function(severity)
	return function(diagnostic)
		diagnostic.severity = vim.diagnostic.severity[severity]
	end
end
local null_ls = require("null-ls")
null_ls.setup({
	sources = {
		-- lua
		null_ls.builtins.formatting.stylua,
		-- nix
		null_ls.builtins.code_actions.statix,
		null_ls.builtins.diagnostics.statix,
		null_ls.builtins.formatting.nixpkgs_fmt,
		-- js/ts
		null_ls.builtins.formatting.prettierd,
		null_ls.builtins.code_actions.eslint_d,
		null_ls.builtins.diagnostics.eslint_d.with({
			method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
			diagnostics_postprocess = force_diagnostic_severity("INFO"),
			filter = function(diagnostic)
				if diagnostic.message then
					return diagnostic.message:lower():match("no eslint configuration found") == nil
				else
					return true
				end
			end,
		}),
		-- shell
		null_ls.builtins.code_actions.shellcheck,
		null_ls.builtins.diagnostics.shellcheck.with({
			diagnostics_postprocess = force_diagnostic_severity("INFO"),
		}),
		null_ls.builtins.formatting.shfmt.with({
			extra_args = { "--indent", "2" },
		}),
		-- python
		null_ls.builtins.diagnostics.ruff,
		null_ls.builtins.formatting.black,
		null_ls.builtins.formatting.isort,
	},
})

vim.keymap.set("n", "gd", require("telescope.builtin").lsp_definitions, { desc = "Goto/find definitions" })
vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, { desc = "Find references" })
vim.keymap.set("n", "gh", vim.lsp.buf.hover, { desc = "Hover docs" })
vim.keymap.set("n", "gI", vim.lsp.buf.implementation, { desc = "Goto implementation" })
vim.keymap.set("i", "<C-i>", function()
	require("cmp").mapping.close()(function() end) -- requires a fallback() arg or will throw
	vim.lsp.buf.signature_help()
end, { desc = "Signature Documentation" })

vim.keymap.set("n", [[\a]], function()
	if vim.b._autocomplete_disabled then
		require("cmp").setup.buffer({})
		print("autocomplete enabled in buffer")
	else
		require("cmp").setup.buffer({ completion = { autocomplete = false } })
		print("autocomplete disabled in buffer")
	end
	vim.b._autocomplete_disabled = not vim.b._autocomplete_disabled
end, { desc = "Toggle buffer autocomplete" })

vim.diagnostic.config({ signs = false })
-- }}}

-- completions {{{
require("nvim-autopairs").setup()

local cmp = require("cmp")
local cmp_autopairs = require("nvim-autopairs.completion.cmp")

cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

cmp.setup({
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-y>"] = cmp.mapping.confirm({ select = true }),
		["<C-k>"] = cmp.mapping(cmp.mapping.complete({}), { "i", "c" }),
		["<C-e>"] = cmp.mapping({
			i = cmp.mapping.abort(),
			c = cmp.mapping.close(),
		}),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
		{ name = "nvim_lua" },
	}, {
		{ name = "path" },
		{
			name = "buffer",
			options = {
				get_bufnrs = function()
					return vim.api.nvim_list_bufs()
				end,
			},
		},
	}),
	formatting = {
		format = require("lspkind").cmp_format(),
	},
})
-- }}}

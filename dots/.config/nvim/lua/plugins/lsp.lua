-- improve ]d and [d behavior
vim.diagnostic.config({
	jump = {
		float = true,
		wrap = true,
	},
})

return {
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				{ path = "~/nixfiles/dots/.config/nvim", words = { "vim" } },
			},
		},
	},

	-- LSP configuration plugin
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			-- LspAttach autocmd for keymaps and navic
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					local bufnr = args.buf

					-- Attach navic if server supports document symbols
					if client and client.server_capabilities.documentSymbolProvider then
						require("nvim-navic").attach(client, bufnr)
					end

					-- LSP keymaps (only active in buffers with LSP)
					local function map(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
					end

					map("n", "gd", "<cmd>Telescope lsp_definitions<cr>", "Goto/find definitions")
					-- map("n", "gr", "<cmd>Telescope lsp_references<cr>", "Find references")
					map("n", "gh", vim.lsp.buf.hover, "Hover docs")
					map("n", "gI", vim.lsp.buf.implementation, "Goto implementation")
					map("i", "<C-i>", vim.lsp.buf.signature_help, "Signature Documentation")
				end,
			})

			-- LSP server configurations
			local lsp_servers = {
				bashls = {},
				cssls = {},
				dockerls = {},
				gopls = {},
				html = {},
				jsonls = {
					settings = {
						validate = { enable = true },
						schemas = require("schemastore").json.schemas(),
					},
				},
				lua_ls = {
					settings = {
						Lua = {
							runtime = { version = "LuaJIT" },
							diagnostics = { globals = { "vim" } },
							workspace = { checkThirdParty = false },
							telemetry = { enable = false },
						},
					},
				},
				nixd = {},
				pyright = {},
				rust_analyzer = {},
				solargraph = {},
				tailwindcss = {},
				terraformls = {},
				vimls = {},
				yamlls = {
					settings = {
						schemas = require("schemastore").yaml.schemas(),
					},
				},
			}

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities =
				vim.tbl_deep_extend("force", capabilities, require("blink.cmp").get_lsp_capabilities({}, false))

			-- Setup typescript-tools
			require("typescript-tools").setup({
				capabilities = capabilities,
			})

			-- Setup all other LSP servers
			for name, config in pairs(lsp_servers) do
				config.capabilities = capabilities
				vim.lsp.config(name, config)
				vim.lsp.enable(name)
			end

			-- Setup markdown_oxide with special capabilities
			local markdown_oxide_capabilities = vim.deepcopy(capabilities)
			markdown_oxide_capabilities.workspace = { didChangeWatchedFiles = { dynamicRegistration = true } }
			vim.lsp.config("markdown_oxide", {
				capabilities = markdown_oxide_capabilities,
			})
			vim.lsp.enable("markdown_oxide")

			-- LSP handlers
			vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
				border = "rounded",
			})

			vim.diagnostic.config({ signs = false })
		end,
	},

	-- TypeScript tools
	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
	},

	-- JSON/YAML schemas
	{
		"b0o/schemastore.nvim",
		lazy = true,
	},
}

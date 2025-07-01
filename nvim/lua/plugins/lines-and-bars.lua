return {
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"SmiteshP/nvim-navic",
		},
		lazy = true,
		event = "VeryLazy",
		config = function()
			-- modify the theme so sections don't change color with mode
			local lualine_theme = vim.deepcopy(require("lualine.utils.loader").load_theme("catppuccin"))
			lualine_theme.insert = nil
			lualine_theme.replace = nil
			lualine_theme.visual = nil
			lualine_theme.command = nil

			local navic = require("nvim-navic")
			require("lualine").setup({
				options = {
					theme = lualine_theme,
					globalstatus = true,
					disabled_filetypes = {
						winbar = { "", "neo-tree", "Outline", "fugitive" },
					},
				},
				sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = { "lsp_progress" },
					lualine_x = { "diagnostics" },
					lualine_y = { "branch", "diff" },
					lualine_z = { "vim.fs.basename(vim.fn.getcwd())" },
				},
				winbar = {
					lualine_b = { { "filename", path = 1 } },
					lualine_c = {
						{
							function()
								return navic.get_location()
							end,
							cond = function()
								return navic.is_available()
							end,
						},
					},
				},
				inactive_winbar = {
					lualine_b = { { "filename", path = 1 } },
				},
				tabline = {
					lualine_a = {
						{
							"tabs",
							mode = 1,
							max_length = vim.o.columns,
							component_separators = { left = "", right = "" },
							section_separators = { left = "", right = "" },
							fmt = function(_, context)
								local winnr = vim.fn.tabpagewinnr(context.tabnr)
								local tabcwd = vim.fs.basename(vim.fn.getcwd(winnr, context.tabnr))
								return "[" .. context.tabnr .. ": " .. tabcwd .. "]"
							end,
						},
					},
				},
			})
			vim.o.showtabline = 1 -- override lualine default
		end,
	},
}

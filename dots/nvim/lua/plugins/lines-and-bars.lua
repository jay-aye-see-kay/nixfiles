-- Lualine statusline and nvim-navic breadcrumbs
return {
	-- Breadcrumb navigation
	{
		"SmiteshP/nvim-navic",
		lazy = true,
	},

	-- Lualine statusline
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "SmiteshP/nvim-navic" },
		config = function()
			local navic = require("nvim-navic")
			-- the theme's lualine palette tints the c section (which fills the bar)
			-- even with transparent = true, so clear it
			local theme = vim.deepcopy(require("lualine.themes.github_light"))
			for _, mode in pairs(theme) do
				if mode.c then
					mode.c.bg = "NONE"
				end
			end
			require("lualine").setup({
				options = {
					theme = theme,
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
					-- inactive sections have no bg, so the separator renders as a stray triangle
					lualine_b = { { "filename", path = 1, separator = "" } },
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

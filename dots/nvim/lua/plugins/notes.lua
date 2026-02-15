-- User commands for logbook
local function open_logbook_cmd(days_from_today)
	return function()
		local date_offset = (days_from_today or 0) * 24 * 60 * 60
		local filename = os.date("%Y-%m-%d", os.time() + date_offset) .. ".md"
		local todays_journal_file = "~/obsidian/notes/daily/" .. filename
		vim.cmd("edit " .. todays_journal_file)
	end
end

vim.api.nvim_create_user_command("LogbookToday", open_logbook_cmd(), {})
vim.api.nvim_create_user_command("LogbookYesterday", open_logbook_cmd(-1), {})
vim.api.nvim_create_user_command("LogbookTomorrow", open_logbook_cmd(1), {})

-- Autocmds for markdown files
vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = { "markdown", "md" },
	callback = function()
		vim.wo.foldlevel = 99
		vim.wo.foldmethod = "expr"
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = { "text", "markdown", "md" },
	callback = function()
		vim.opt_local.wrap = true
	end,
})

-- Note-taking plugins
return {
	-- Toggle markdown checkboxes
	{
		"opdavies/toggle-checkbox.nvim",
		lazy = true,
		cmd = "ToggleCheckbox",
		keys = {
			{ "\\\\", "<cmd>lua require('toggle-checkbox').toggle()<cr>", desc = "Toggle Checkbox" },
		},
	},

	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {
			render_modes = true,
			code = {
				border = "thin",
			},
			html = {
				comment = {
					conceal = false,
				},
			},
			checkbox = {
				unchecked = {
					icon = "-  󰄱 ",
				},
				checked = {
					icon = "-  󰱒 ",
				},
			},
		},
	},
}

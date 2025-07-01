local h = require("_cfg.helpers")

h.autocmd({ "FileType" }, {
	pattern = { "markdown", "md" },
	callback = function()
		vim.wo.foldlevel = 99
		vim.wo.foldmethod = "expr"
		vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
	end,
})

h.autocmd({ "FileType" }, {
	pattern = { "text", "markdown", "md" },
	callback = function()
		vim.opt_local.wrap = true
	end,
})

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

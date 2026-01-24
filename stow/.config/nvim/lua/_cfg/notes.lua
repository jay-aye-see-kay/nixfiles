local h = require("_cfg.helpers")

-- Markdown helpers for headings
H = {
	indexOf = function(array, value)
		for idx, v in ipairs(array) do
			if v == value then
				return idx
			end
		end
		return nil
	end,
	--
	status_config = {
		IDEA = { icon = " ", color = "hint" },
		TODO = { icon = " ", color = "info" },
		IN_PROGRESS = { icon = " ", color = "test" },
		WAITING = { icon = "⏲ ", color = "warning" },
		DONE = { icon = " ", color = "test" },
	},
	--
	statuses = { "TODO", "IN_PROGRESS", "WAITING", "DONE" },
	--
	advance = function()
		local line = vim.api.nvim_get_current_line()
		H.update_status(H.get_next_status(line))()
	end,
	--
	get_next_status = function(line)
		local heading_status = H.get_heading_status(line)
		if heading_status ~= nil then
			local status_idx = H.indexOf(H.statuses, heading_status) or 0
			return H.statuses[status_idx + 1] or H.statuses[1] -- handles wrap around and unknown statuses
		else
			return H.statuses[1]
		end
	end,
	--
	get_heading_status = function(line)
		return string.match(line, "^%s*#+%s*([%a-_]+):")
	end,
	--
	is_line_a_heading = function(line)
		return string.match(line, "^%s*#+") ~= nil
	end,
	--
	update_status = function(new_status)
		return function()
			local line = vim.api.nvim_get_current_line()
			if not H.is_line_a_heading(line) then
				return
			end
			local heading_prefix = string.match(line, "^%s*#+")
			local heading_status = H.get_heading_status(line)
			if heading_status ~= nil then
				local new_line = string.gsub(line, heading_status, new_status)
				vim.api.nvim_set_current_line(new_line)
			elseif heading_prefix ~= nil then
				local new_line = string.gsub(line, heading_prefix, heading_prefix .. " " .. new_status .. ":")
				vim.api.nvim_set_current_line(new_line)
			end
		end
	end,
}

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

h.autocmd({ "FileType" }, {
	pattern = { "markdown", "md" },
	callback = function(ctx)
		vim.keymap.set("n", "<leader>xt", H.update_status("TODO"), { desc = "mark todo", buffer = true })
		vim.keymap.set("n", "<leader>xp", H.update_status("IN_PROGRESS"), { desc = "mark progress", buffer = true })
		vim.keymap.set("n", "<leader>xw", H.update_status("WAITING"), { desc = "mark waiting", buffer = true })
		vim.keymap.set("n", "<leader>xx", H.update_status("DONE"), { desc = "mark done", buffer = true })
		vim.keymap.set("n", "<leader>xd", H.update_status("DONE"), { desc = "mark done", buffer = true })
		vim.keymap.set("n", "<leader>xn", H.advance, { desc = "advance heading status", buffer = true })
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

	-- Headlines for markdown
	{
		"lukas-reineke/headlines.nvim",
		lazy = true,
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		ft = { "markdown", "rmd", "orgmode", "neorg" },
		opts = {
			markdown = { fat_headlines = false },
			rmd = { fat_headlines = false },
			norg = { fat_headlines = false },
			org = { fat_headlines = false },
		},
	},

	-- Markdown preview
	{
		"iamcco/markdown-preview.nvim",
		lazy = true,
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
	},
}

local h = require("_cfg.helpers")

-- notes/wiki {{{
require("mkdnflow").setup({
	modules = {
		bib = false,
		folds = false,
	},
	to_do = {
		symbols = { " ", "-", "x" },
		update_parents = false,
		not_started = " ",
		complete = "x",
	},
	mappings = {
		MkdnGoBack = false,
		MkdnGoForward = false,
		MkdnYankAnchorLink = false,
		MkdnFoldSection = false,
		MkdnUnfoldSection = false,
	},
})

h.autocmd({ "FileType" }, {
	pattern = { "markdown", "md" },
	callback = function(ctx)
		vim.wo.foldlevel = 99
		vim.wo.foldmethod = "expr"
		vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
		require("tsnode-marker").set_automark(ctx.buf, {
			target = { "code_fence_content", "indented_code_block" },
			hl_group = "CodeBlockBackground",
		})
		-- require("tsnode-marker").set_automark(ctx.buf, {
		-- 	-- FIXME need atx_heading when it has atx_h1_marker as a child
		-- 	target = { "atx_h1_marker", "indented_code_block" },
		-- 	hl_group = "CodeBlockBackground",
		-- })
	end,
})

h.autocmd({ "FileType" }, {
	pattern = { "text", "markdown", "md" },
	callback = function()
		vim.opt_local.wrap = true
	end,
})

local function open_logbook(days_from_today)
	local date_offset = (days_from_today or 0) * 24 * 60 * 60
	local filename = os.date("%Y-%m-%d-%A", os.time() + date_offset) .. ".md"
	local todays_journal_file = "~/notes/logbook/" .. filename
	vim.cmd("edit " .. todays_journal_file)
end

function LogbookToday()
	open_logbook()
end

function LogbookYesterday()
	open_logbook(-1)
end

function LogbookTomorrow()
	open_logbook(1)
end

vim.cmd([[command! LogbookToday :call v:lua.LogbookToday()]])
vim.cmd([[command! LogbookYesterday :call v:lua.LogbookYesterday()]])
vim.cmd([[command! LogbookTomorrow :call v:lua.LogbookTomorrow()]])
-- }}}

-- markdown notes experiment
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
		IDEA = { icon = " ", color = "hint" },
		TODO = { icon = " ", color = "info" },
		IN_PROGRESS = { icon = " ", color = "test" },
		WAITING = { icon = "⏲ ", color = "warning" },
		DONE = { icon = " ", color = "test" },
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

h.autocmd({ "FileType" }, {
	pattern = { "markdown", "md" },
	callback = function(ctx)
		require("todo-comments").setup({
			signs = false,
			highlight = { comments_only = false },
			keywords = H.status_config,
			merge_keywords = false,
		})

		vim.keymap.set("n", "<leader>xt", H.update_status("TODO"), { desc = "mark todo" })
		vim.keymap.set("n", "<leader>xp", H.update_status("IN_PROGRESS"), { desc = "mark progress" })
		vim.keymap.set("n", "<leader>xw", H.update_status("WAITING"), { desc = "mark waiting" })
		vim.keymap.set("n", "<leader>xx", H.update_status("DONE"), { desc = "mark done" })
		vim.keymap.set("n", "<leader>xd", H.update_status("DONE"), { desc = "mark done" })
		vim.keymap.set("n", "<leader>xn", H.advance, { desc = "advance heading status" })
	end,
})

vim.keymap.set(
	"n",
	"<leader>nT",
	"<CMD>TodoTrouble cwd=~/notes keywords=TODO,IN_PROGRESS,WAITING<CR>",
	{ desc = "list incomplete items in notes" }
)
vim.keymap.set("n", "<leader>nI", "<CMD>TodoTrouble cwd=~/notes keywords=IDEA<CR>", { desc = "list *ideas* in notes" })

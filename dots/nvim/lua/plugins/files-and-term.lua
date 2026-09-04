-- File explorer and terminal configuration
local plugins = {
	-- Fyler file manager: file tree sidebar + oil-style buffer editing.
	-- Mutations happen by editing the buffer (rename/move, duplicate/copy,
	-- delete lines, add lines) and writing it (`:w`), with a confirm prompt.
	{
		"FylerOrg/fyler.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			extensions = {
				git = { enabled = true },
				trash = { enabled = true },
				watcher = { enabled = true },
			},
			integrations = { icon = "nvim_web_devicons" },
			kind_presets = {
				split_left_most = { width = 30 },
			},
			ui = {
				hidden_items = {
					-- fyler deep-merges config, so the default `switches = { "dotfiles" }`
					-- cannot be cleared by passing an empty table. `always_visible` is
					-- checked before switches, so this pattern keeps dotfiles always shown.
					always_visible = { "/%.[^/]*$" },
				},
			},
		},
	},
}

-- Terminal configuration
vim.keymap.set("t", "<ESC>", [[<C-\><C-n>]])
vim.keymap.set("t", "<A-ESC>", "<ESC>")

vim.api.nvim_create_autocmd({ "TermEnter" }, {
	command = "setlocal winhighlight=Normal:ActiveTerm",
})
vim.api.nvim_create_autocmd({ "TermLeave" }, {
	command = "setlocal winhighlight=Normal:NC",
})

vim.api.nvim_create_autocmd({ "TermOpen" }, {
	callback = function()
		-- stops terminal side scrolling
		vim.cmd([[ setlocal nonumber norelativenumber signcolumn=no ]])
		-- put this back to default
		vim.opt.scrolloff = 0
		vim.opt.sidescrolloff = 0
		-- ctrl-c, ctrl-p, ctrl-n, enter should all be passed through from normal mode
		vim.keymap.set("n", "<C-c>", [[ i<C-c><C-\><C-n> ]], { buffer = 0 })
		vim.keymap.set("n", "<C-n>", [[ i<C-n><C-\><C-n> ]], { buffer = 0 })
		vim.keymap.set("n", "<C-p>", [[ i<C-p><C-\><C-n> ]], { buffer = 0 })
		vim.keymap.set("n", "<CR>", [[ i<CR><C-\><C-n> ]], { buffer = 0 })
	end,
})

-- pass through OSC 777 notifications to parent terminal (allows notifications in from pi to ghostty)
vim.api.nvim_create_autocmd("TermRequest", {
	callback = function(ev)
		local seq = ev.data and ev.data.sequence
		if seq and seq:match("^\027]777;") then
			io.stdout:write(seq)
		end
	end,
})

return plugins

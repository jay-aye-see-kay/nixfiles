local h = require("_cfg.helpers")

-- file tree {{{
vim.g.neo_tree_remove_legacy_commands = 1

require("neo-tree").setup({
	window = {
		position = "left",
		width = 30,
		mappings = {
			["<space>"] = false,
			["z"] = false,
			["l"] = "open",
			["h"] = "close_node",
		},
	},
	filesystem = {
		filtered_items = {
			visible = true,
			hide_dotfiles = false,
		},
		hijack_netrw_behavior = "open_current",
		use_libuv_file_watcher = true,
		follow_current_file = { enabled = true },
		window = {
			mappings = {
				["H"] = "navigate_up",
				["L"] = "set_root",
				["."] = "toggle_hidden",
				["/"] = false,
				["D"] = "fuzzy_finder_directory",
				["<c-x>"] = "clear_filter",
				["[g"] = "prev_git_modified",
				["]g"] = "next_git_modified",
				["a"] = { "add", config = { show_path = "relative" } },
				["c"] = { "copy", config = { show_path = "relative" } },
				["m"] = { "move", config = { show_path = "relative" } },
			},
		},
	},

	-- the below config fixes icons for nerdfonts v3, hopefully it won't be necessary for long
	default_component_configs = {
		icon = {
			folder_empty = "󰜌",
			folder_empty_open = "󰜌",
		},
		git_status = {
			symbols = {
				renamed = "󰁕",
				unstaged = "󰄱",
			},
		},
	},
	document_symbols = {
		kinds = {
			File = { icon = "󰈙", hl = "Tag" },
			Namespace = { icon = "󰌗", hl = "Include" },
			Package = { icon = "󰏖", hl = "Label" },
			Class = { icon = "󰌗", hl = "Include" },
			Property = { icon = "󰆧", hl = "@property" },
			Enum = { icon = "󰒻", hl = "@number" },
			Function = { icon = "󰊕", hl = "Function" },
			String = { icon = "󰀬", hl = "String" },
			Number = { icon = "󰎠", hl = "Number" },
			Array = { icon = "󰅪", hl = "Type" },
			Object = { icon = "󰅩", hl = "Type" },
			Key = { icon = "󰌋", hl = "" },
			Struct = { icon = "󰌗", hl = "Type" },
			Operator = { icon = "󰆕", hl = "Operator" },
			TypeParameter = { icon = "󰊄", hl = "Type" },
			StaticMethod = { icon = "󰠄 ", hl = "Function" },
		},
	},
	source_selector = {
		sources = {
			{ source = "filesystem", display_name = " 󰉓 Files " },
			{ source = "git_status", display_name = " 󰊢 Git " },
		},
	},
})
-- }}}

--- Opens neotree git_status, showing changes since branch off default
local function neotree_merge_base(prefix)
	return function()
		local cmd_output = vim.fn.systemlist("git guess-default-branch")
		if #cmd_output ~= 1 then
			print("git guess-default-branch failed")
			return
		end
		local default_branch = cmd_output[1]
		local merge_base = vim.fn.systemlist("git merge-base " .. default_branch .. " HEAD")[1]
		print("merge base with '" .. default_branch .. "' is '" .. merge_base .. "'")
		vim.cmd(prefix .. " | Neotree current source=git_status git_base=" .. merge_base)
	end
end
vim.keymap.set("n", "<leader>egh", neotree_merge_base("aboveleft vsplit"), { desc = "neotree merge_base to left" })
vim.keymap.set("n", "<leader>egl", neotree_merge_base("belowright vsplit"), { desc = "neotree merge_base to right" })
vim.keymap.set("n", "<leader>egk", neotree_merge_base("aboveleft split"), { desc = "neotree merge_base above" })
vim.keymap.set("n", "<leader>egj", neotree_merge_base("belowright split"), { desc = "neotree merge_base below" })
vim.keymap.set("n", "<leader>eg.", neotree_merge_base("echo"), { desc = "neotree merge_base in place" })
vim.keymap.set("n", "<leader>eg,", neotree_merge_base("tabnew"), { desc = "neotree merge_base in new tab" })

-- {{{ terminal
vim.keymap.set("t", "<ESC>", [[<C-\><C-n>]])

h.autocmd({ "TermEnter" }, {
	command = "setlocal winhighlight=Normal:ActiveTerm",
})
h.autocmd({ "TermLeave" }, {
	command = "setlocal winhighlight=Normal:NC",
})

h.autocmd({ "TermOpen" }, {
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

require("term-edit").setup({
	prompt_end = "❯ ",
})
-- }}}

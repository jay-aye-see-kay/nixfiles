local plugins = require("nln").plugins

-- pro debugging
plugins["debugprint.nvim"] = {
	lazy = true,
	event = "VeryLazy",
	opts = {},
}

-- {{{ regular debugging
plugins["nvim-dap-ui"] = { lazy = true, opts = {} }
plugins["nvim-dap-virtual-text"] = {
	lazy = true,
	opts = { virt_text_pos = "eol" },
}

plugins["nvim-dap-go"] = { lazy = true, opts = {} }
plugins["nvim-dap-python"] = {
	lazy = true,
	config = function()
		require("dap-python").setup(vim.g.python3_host_prog)
	end,
}

plugins["nvim-dap"] = {
	lazy = true,
	dependencies = {
		"nvim-dap-ui",
		"nvim-dap-virtual-text",
		"nvim-dap-go",
		"nvim-dap-python",
	},
}

vim.keymap.set("n", "<space>dR", function()
	require("dap").clear_breakpoints()
end, { desc = "clear breakpoints" })
vim.keymap.set("n", "<space>db", function()
	require("dap").toggle_breakpoint()
end, { desc = "toggle breakpoint" })
vim.keymap.set("n", "<space>dc", function()
	require("dap").continue()
end, { desc = "continue" })
vim.keymap.set("n", "<space>dr", function()
	require("dap").repl.open()
end, { desc = "repl" })
vim.keymap.set("n", "<space>di", function()
	require("dap").step_into()
end, { desc = "step into" })
vim.keymap.set("n", "<space>do", function()
	require("dap").step_over()
end, { desc = "step over" })
vim.keymap.set("n", "<space>dt", function()
	require("dap").step_out()
end, { desc = "step out" })
vim.keymap.set("n", "<space>du", function()
	require("dapui").toggle()
end, { desc = "toggle" })
vim.keymap.set("n", "<space>dC", function()
	require("dap").run_to_cursor()
end, { desc = "run to cursor" })

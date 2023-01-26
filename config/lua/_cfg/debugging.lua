-- {{{ pro debugging
require("debugprint").setup()

require("which-key").register({
	name = "debugprint",
	p = "plain below",
	P = "plain above",
	v = "variable below",
	V = "variable above",
	o = "variable below [motion]",
	O = "variable above [motion]",
	x = { require("debugprint").deleteprints, "clear debug prints" },
}, {
	prefix = "g?",
})
-- }}}

-- {{{ regular debugging
require("dapui").setup({})
require("dap-go").setup()
require("nvim-dap-virtual-text").setup({})

vim.keymap.set("n", "<space>dR", require("dap").clear_breakpoints, { desc = "clear breakpoints" })
vim.keymap.set("n", "<space>db", require("dap").toggle_breakpoint, { desc = "toggle breakpoint" })
vim.keymap.set("n", "<space>dc", require("dap").continue, { desc = "continue" })
vim.keymap.set("n", "<space>dr", require("dap").repl.open, { desc = "repl" })
vim.keymap.set("n", "<space>di", require("dap").step_into, { desc = "step into" })
vim.keymap.set("n", "<space>do", require("dap").step_over, { desc = "step over" })
vim.keymap.set("n", "<space>dt", require("dap").step_out, { desc = "step out" })

vim.keymap.set("n", "<space>du", require("dapui").toggle, { desc = "toggle" })
vim.keymap.set("n", "<space>dc", require("dap").run_to_cursor, { desc = "run to cursor" })
-- }}}

-- Treesitter configuration (nvim-treesitter `main` branch / nvim 0.12 API)
-- Note: nvim-treesitter, nvim-treesitter-grammars and nvim-treesitter-textobjects
-- are provided by Nix and already on the runtimepath (parsers bundled).
--
-- The old `main` branch dropped the module system entirely:
--   * no more require("nvim-treesitter.configs").setup{ highlight/indent/... }
--   * no more incremental_selection module
--   * textobjects are now plain functions you bind yourself
-- See: https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md

-- Minimal setup (parsers come from Nix, so no ensure_install needed)
require("nvim-treesitter").setup({})

-- Textobjects config (select lookahead etc.)
require("nvim-treesitter-textobjects").setup({
	select = {
		lookahead = true,
	},
	move = {
		set_jumps = true,
	},
})

-- Highlighting + indentation are now enabled per-buffer.
local ts_group = vim.api.nvim_create_augroup("user_treesitter", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
	group = ts_group,
	callback = function(args)
		local ft = args.match
		local lang = vim.treesitter.language.get_lang(ft) or ft

		-- only start if a parser is actually available
		if not vim.treesitter.language.add(lang) then
			return
		end

		vim.treesitter.start(args.buf, lang)

		-- ruby: keep additional vim regex highlighting, skip ts indent
		if ft == "ruby" then
			vim.bo[args.buf].syntax = "on"
		else
			vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
	end,
})

-- Textobjects keymaps (replaces the old `keymaps` tables) ---------------------
local select = require("nvim-treesitter-textobjects.select")
local swap = require("nvim-treesitter-textobjects.swap")
local move = require("nvim-treesitter-textobjects.move")

local function map(mode, lhs, fn, desc)
	vim.keymap.set(mode, lhs, fn, { silent = true, desc = desc })
end

-- select
local selects = {
	["aa"] = "@parameter.outer",
	["ia"] = "@parameter.inner",
	["af"] = "@function.outer",
	["if"] = "@function.inner",
	["ac"] = "@class.outer",
	["ic"] = "@class.inner",
	["a/"] = "@comment.outer",
}
for lhs, query in pairs(selects) do
	map({ "x", "o" }, lhs, function()
		select.select_textobject(query, "textobjects")
	end, "TS select " .. query)
end

-- swap
map("n", "<leader>pl", function()
	swap.swap_next("@parameter.inner")
end, "TS swap next parameter")
map("n", "<leader>ph", function()
	swap.swap_previous("@parameter.inner")
end, "TS swap previous parameter")

-- move
map({ "n", "x", "o" }, "]m", function()
	move.goto_next_start("@function.outer", "textobjects")
end, "TS next function start")
map({ "n", "x", "o" }, "]M", function()
	move.goto_next_end("@function.outer", "textobjects")
end, "TS next function end")
map({ "n", "x", "o" }, "[m", function()
	move.goto_previous_start("@function.outer", "textobjects")
end, "TS previous function start")
map({ "n", "x", "o" }, "[M", function()
	move.goto_previous_end("@function.outer", "textobjects")
end, "TS previous function end")

-- NOTE: incremental_selection (<c-space>) was removed upstream in the `main`
-- branch and has no drop-in replacement. Left unbound for now.

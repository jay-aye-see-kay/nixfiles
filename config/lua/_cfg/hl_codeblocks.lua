local h = require("_cfg.helpers")

--[[
WIP function to highlight codeblocks in markdown, the idea is to run this function on TextChanged or similar autocmd

The only way to highlight full width background is with the "signs" feature, so we have to abuse this a bit,
signs are made for debuggers or IDE like features to write feedback over code. But we can define a sign called
"codeblock" that we can use to HL arbitrary lines.

We can then find codeblocks using a treesitter query, then iterate over each one's lines and highlighting it.

TODO
- To speed things up I should read all created signs with sign_getplaced(), diff the lines the are highlighted
with the ones that need to be then, place and unplace in bulk with sign_placelist() and sign_unplacelist()

- I should also try running this in a co-routine so it's non blocking on larger files (idk if slow but) should be safe
--]]
local hl_codeblocks = function(bufnr)
	-- setup sign and colour for it
	vim.api.nvim_set_hl(0, "codeBlockBackground", { bg = require("zenbones").Normal.bg.li(70).hex })
	vim.fn.sign_define("codeblock", { linehl = "codeBlockBackground", numhl = "codeBlockBackground" })

	local placed = vim.fn.sign_getplaced(bufnr, { group = "codeblock_hl" })
	vim.fn.sign_unplacelist(placed[1].signs)

	-- place sign on each codeblock line
	local query = vim.treesitter.parse_query("markdown", "(code_fence_content) @md_code_block")
	local source = vim.treesitter.get_parser(bufnr, "markdown"):parse()[1]:root()
	for _, node in query:iter_captures(source, bufnr) do
		for i = node:start() + 1, node:end_() do
			vim.fn.sign_place(1, "codeblock_hl", "codeblock", bufnr, { lnum = i })
		end
	end
end

h.autocmd({ "BufNewFile", "BufReadPost", "BufEnter", "TextChanged", "TextChangedI" }, {
	pattern = { "*.markdown", "*.md" },
	callback = function(opts)
		hl_codeblocks(opts.buf)
	end,
})

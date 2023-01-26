local h = require("_cfg.helpers")

-- snippets {{{
require("luasnip.loaders.from_vscode").lazy_load()

-- these need to work in insert and select mode for some reason
local function snip_map(lhs, rhs)
	h.map("i", lhs, rhs)
	h.map("s", lhs, rhs)
end

snip_map("<C-j>", "<Plug>luasnip-expand-snippet")
snip_map("<C-l>", "<Plug>luasnip-jump-next")
snip_map("<C-h>", "<Plug>luasnip-jump-prev")

local ls = require("luasnip")
local l = require("luasnip.extras").lambda
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node
local vsc = ls.parser.parse_snippet

local js_snippets = {
	-- React.useState()
	s("us", {
		t("const ["),
		i(1, "foo"),
		t(", set"),
		l(l._1:gsub("^%l", string.upper), 1),
		t("] = useState("),
		i(2),
		t(")"),
	}),
	-- React.useEffect()
	vsc("ue", "useEffect(() => {\n\t${1}\n}, [${0}])", {}),
	-- basics + keywords
	vsc("c", "const ${1} = ${0}", {}),
	vsc("l", "let ${1} = ${0}", {}),
	vsc("e", "export ${0}", {}),
	vsc("aw", "await ${0}", {}),
	vsc("as", "async ${0}", {}),
	vsc("d", "debugger", {}),
	-- function
	vsc("f", "function ${1}(${2}) {\n\t${3}\n}", {}),
	-- anonymous function
	vsc("af", "(${1}) => $0", {}),
	-- skeleton function
	vsc("sf", "function ${1}(${2}): ${3:void} {\n\t${0:throw new Error('Not implemented')}\n}", {}),
	-- throw
	vsc("tn", "throw new Error(${0})", {}),
	-- comments
	vsc("jsdoc", "/**\n * ${0}\n */", {}),
	vsc("/", "/* ${0} */", {}),
	vsc("/**", "/** ${0} */", {}),
	vsc("eld", "/* eslint-disable-next-line ${0} */", {}),
	-- template string variable
	vsc({ trig = "v", wordTrig = false }, "\\${${1}}", {}),
	-- verbose undefined checks
	vsc("=u", "=== undefined", {}),
	vsc("!u", "!== undefined", {}),
}

ls.add_snippets("all", {
	s("date", { i(1, os.date("%Y-%m-%d")) }),
	vsc({ name = "random number", trig = "rn" }, "$RANDOM", {}),
	vsc({ name = "random hex number", trig = "rh" }, "$RANDOM_HEX", {}),
	vsc({ name = "random uuid", trig = "uuid" }, "$UUID", {}),
	vsc("filename", "$TM_FILENAME", {}),
	vsc("filepath", "$TM_FILEPATH", {}),
	vsc({ trig = "v", wordTrig = false }, "\\${${1}}", {}),
	vsc({ name = "return", trig = "r" }, "return ${0}", {}),
})

ls.add_snippets("markdown", {
	-- task
	vsc("t", "- [ ] ${0}", {}),
	-- code blocks
	vsc("c", "```\n${1}\n```", {}),
	vsc("cj", "```json\n${1}\n```", {}),
	vsc("ct", "```typescript\n${1}\n```", {}),
	vsc("cp", "```python\n${1}\n```", {}),
	vsc("cs", "```bash\n${1}\n```", {}),
	vsc("cn", "```nix\n${1}\n```", {}),
	vsc("cc", "```c\n${1}\n```", {}),
})

ls.add_snippets("javascript", js_snippets)
ls.add_snippets("typescript", js_snippets)
ls.add_snippets("javascriptreact", js_snippets)
ls.add_snippets("typescriptreact", js_snippets)
-- }}}

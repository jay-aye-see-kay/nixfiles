-- run these tests with
-- ```
-- nvim --headless -c 'PlenaryBustedFile config/tests/ai_buf_chat.lua'`
-- ```

vim.opt.rtp:prepend("~/code/neovim-flake/config/")
vim.opt.packpath = vim.opt.rtp:get()
local M = require("_cfg.ai_buf_chat")

local test_lines = [[
<!--​ 🔧 settings ​-->
```json
{ "model": "gpt-3.5-turbo" }
```
<!--​ 💻 system ​-->
Behave like X
<!--​ 👤 user ​-->
I want you to do Y
<!--​ 💁 assistant ​-->
Sure done!
<!--​ 👤 user ​-->
I want you to do Z
]]

local expected_json_section = {
	type = "settings",
	lines = {
		"```json",
		'{ "model": "gpt-3.5-turbo" }',
		"```",
	},
}

local expected_sections = {
	expected_json_section,
	{ type = "system", lines = { "Behave like X" } },
	{ type = "user", lines = { "I want you to do Y" } },
	{ type = "assistant", lines = { "Sure done!" } },
	{ type = "user", lines = { "I want you to do Z" } },
}

local expected_api_format = {
	model = "gpt-3.5-turbo",
	messages = {
		{ role = "system", content = "Behave like X" },
		{ role = "user", content = "I want you to do Y" },
		{ role = "assistant", content = "Sure done!" },
		{ role = "user", content = "I want you to do Z" },
	},
}

describe("converting a buffer's lines to an object we can sent to openai", function()
	it("can break the lines down into sections", function()
		assert.same(expected_sections, M.group_lines_into_sections(M.split_into_lines(test_lines)))
	end)

	it("can parse the json in the settings sections", function()
		assert.same({ model = "gpt-3.5-turbo" }, M.parse_settings_section(expected_json_section))
	end)

	it("can break the lines down into sections", function()
		assert.same(expected_api_format, M.sections_to_api_format(expected_sections))
	end)
end)

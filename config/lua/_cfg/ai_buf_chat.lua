local initial_text = [[
<!--​ 🔧 settings ​-->

```json
{ "model": "gpt-3.5-turbo" }
```

<!--​ 💻 system ​-->

You're a programming assistant that responds with brief and accurate explanations, preferring code snippets where appropriate
<!--​ 👤 user ​-->
]]

local M = {}

M.markers = {
	settings = "<!--​ 🔧 settings ​-->",
	system = "<!--​ 💻 system ​-->",
	user = "<!--​ 👤 user ​-->",
	assistant = "<!--​ 💁 assistant ​-->",
}

M.marker_lines = {
	[M.markers.settings] = "settings",
	[M.markers.system] = "system",
	[M.markers.user] = "user",
	[M.markers.assistant] = "assistant",
}

M.config = {
	chats_dir = "~/notes/ai-chats",
	initial_text = initial_text,
	url = "https://api.openai.com/v1/chat/completions",
	default_settings = {
		model = "gpt-3.5-turbo",
	},
}

-- {{{ helper functions
M.split_into_lines = function(str)
	local lines = {}
	for line in string.gmatch(str, "[^\r\n]+") do
		table.insert(lines, line)
	end
	return lines
end
M.append_line_to_buffer = function(bufnr, line)
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	vim.api.nvim_buf_set_lines(bufnr, line_count, line_count, false, { line })
end
M.delete_last_line_in_buffer = function(bufnr)
	local last_line_num = vim.api.nvim_buf_line_count(bufnr)
	vim.api.nvim_buf_set_lines(bufnr, last_line_num - 1, last_line_num, false, {})
end
M.read_files_in_dir = function(path)
	if vim.fn.isdirectory(vim.fs.normalize(path)) == 0 then
		return {}
	end
	local dir_contents = {}
	for name, type in vim.fs.dir(path) do
		if type == "file" then
			table.insert(dir_contents, name)
		end
	end
	return dir_contents
end
-- }}}

--- break lines from a buffer down into sections
--- @param lines string[]
M.group_lines_into_sections = function(lines)
	local sections = {}
	for _, line in ipairs(lines) do
		if M.marker_lines[line] ~= nil then
			-- we've just entered a new section
			table.insert(sections, { type = M.marker_lines[line], lines = {} })
		elseif sections[#sections] ~= nil then
			-- push line to existign section (ignore if not in section yet)
			table.insert(sections[#sections].lines, line)
		end
	end
	return sections
end

--- parse the setting section
--- TODO allowlist know settings so we don't accidentally pass something
M.parse_settings_section = function(section)
	local filtered_lines = {}
	for _, line in ipairs(section.lines) do
		line = vim.trim(line)
		if line == "" or not vim.startswith(line, "```") then
			table.insert(filtered_lines, line)
		end
	end
	local json_like_string = table.concat(filtered_lines, "\n")
	local _, parsed = pcall(vim.fn.json_decode, json_like_string)
	return parsed
end

--- give a list of sections, convert it to a format we can send to openai endpoint
M.sections_to_api_format = function(sections)
	local messages = {}
	local message_sections = { "system", "user", "assistant" }
	for _, section in ipairs(sections) do
		if vim.tbl_contains(message_sections, section.type) then
			table.insert(messages, {
				role = section.type,
				content = vim.trim(table.concat(section.lines, "\n")),
			})
		end
	end

	local settings_data = nil
	if sections[1] ~= nil and sections[1].type == "settings" then
		settings_data = M.parse_settings_section(sections[1])
	end

	return vim.tbl_extend("force", M.config.default_settings, settings_data, { messages = messages })
end

--- read an ai chat buffer into lines and convert it to a conversation we can send to the api
---@param bufnr integer
M.buffer_to_api = function(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local sections = M.group_lines_into_sections(lines)
	return M.sections_to_api_format(sections)
end

M.send_api = function(bufnr, key)
	M.append_line_to_buffer(bufnr, "")
	M.append_line_to_buffer(bufnr, "Loading...")
	require("plenary.job")
		:new({
			command = "curl",
			args = {
				M.config.url,
				"-H",
				"Content-Type: application/json",
				"-H",
				"Authorization: Bearer " .. key,
				"-d",
				vim.fn.json_encode(M.buffer_to_api(bufnr)),
			},
			on_exit = vim.schedule_wrap(function(response, exit_code)
				if exit_code ~= 0 then
					print("failed")
				end
				local result = table.concat(response:result(), "\n")
				local out = vim.fn.json_decode(result)
				if
					out ~= nil
					and out.choices ~= nil
					and out.choices[1] ~= nil
					and out.choices[1].message ~= nil
					and out.choices[1].message.content ~= nil
				then
					M.delete_last_line_in_buffer(bufnr)
					M.append_line_to_buffer(bufnr, M.markers.assistant)
					M.append_line_to_buffer(bufnr, "")
					local out_lines = M.split_into_lines(out.choices[1].message.content)
					for _, line in ipairs(out_lines) do
						M.append_line_to_buffer(bufnr, line)
					end
					M.append_line_to_buffer(bufnr, "")
					M.append_line_to_buffer(bufnr, M.markers.user)

					local tokens_used = out.usage.total_tokens
					local cents_cost = tokens_used * 0.0002
					print("used " .. tokens_used .. " tokens at an estimated cost of " .. cents_cost .. " cents.")
				end
			end),
		})
		:start()
end

M.get_last_chat_filename = function()
	local chat_files = M.read_files_in_dir(M.config.chats_dir)
	local valid_chat_files = {}
	for _, chat_file in ipairs(chat_files) do
		local date, num = string.match(chat_file, "(%d%d%d%d%-%d%d%-%d%d)_(%d+)%.ai%-chat.md")
		if date ~= nil and num ~= nil then
			table.insert(valid_chat_files, chat_file)
		end
	end
	table.sort(valid_chat_files)
	local last_chat_file = valid_chat_files[#valid_chat_files]
	if last_chat_file == nil then
		print("Not chats found")
	end
	return last_chat_file
end

M.get_new_chat_filename = function()
	local todays_date = os.date("%Y-%m-%d", os.time())
	local new_num = 1

	local last_chat_file = M.get_last_chat_filename()
	if last_chat_file then
		local date, num = string.match(last_chat_file, "(%d%d%d%d%-%d%d%-%d%d)_(%d+)%.ai%-chat.md")
		if date ~= nil and date == todays_date and num ~= nil then
			new_num = tonumber(num) + 1
		end
	end

	local new_num_str = string.format("%04d", new_num)
	return todays_date .. "_" .. new_num_str .. ".ai-chat.md"
end

M.open_last_chat = function()
	local filename = M.get_last_chat_filename()
	if filename then
		filename = vim.fs.normalize(M.config.chats_dir .. "/" .. filename)
		vim.cmd("edit " .. filename)
	end
end

M.open_new_chat = function()
	local filename = M.get_new_chat_filename()
	if filename then
		filename = vim.fs.normalize(M.config.chats_dir .. "/" .. filename)
		vim.cmd("edit " .. filename)
		M.write_initial_text()
	end
end

M.write_initial_text = function(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local initial_lines = M.split_into_lines(M.config.initial_text)
	for _, line in ipairs(initial_lines) do
		M.append_line_to_buffer(bufnr, line)
	end
end

M.is_prefix = function(str1, str2)
	local shorter, longer
	if #str1 <= #str2 then
		shorter, longer = str1, str2
	else
		shorter, longer = str2, str1
	end
	return longer:sub(1, #shorter) == shorter
end

-- do some sensible checks before trying to call ai on the buffer
M.execute_on_current_buffer = function()
	local key = vim.env.OPENAI_API_KEY
	if key == nil then
		print("could not find $OPENAI_API_KEY")
		return
	end
	local current_path = vim.fs.normalize(vim.fn.expand("%:p"))
	local config_path = vim.fs.normalize(M.config.chats_dir)
	if not M.is_prefix(current_path, config_path) then
		print("not in " .. config_path .. " doing nothing")
		return
	end
	local bufnr = vim.api.nvim_get_current_buf()
	M.send_api(bufnr, key)
end

M.setup = function()
	vim.keymap.set("n", "<leader>cc", M.execute_on_current_buffer, { desc = "send buffer to openai" })
	vim.keymap.set("n", "<leader>cn", M.open_new_chat, { desc = "open new ai-chat buffer" })
	vim.keymap.set("n", "<leader>cl", M.open_last_chat, { desc = "open last ai-chat buffer" })
end

return M

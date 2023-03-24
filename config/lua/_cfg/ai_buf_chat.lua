--[[
-- okay so it works!
-- auto save when done
-- keybind to execute
-- shortcut to open last and new chat window
-- loading state
-- maybe a telescope shortcut to
--]]
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

M.default_settings = {
	model = "gpt-3.5-turbo",
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

	return vim.tbl_extend("force", M.default_settings, settings_data, { messages = messages })
end

--- read an ai chat buffer into lines and convert it to a conversation we can send to the api
---@param bufnr integer
M.buffer_to_api = function(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local sections = M.group_lines_into_sections(lines)
	return M.sections_to_api_format(sections)
end

-- TODO pass callback, non-blocking
-- TODO set loading/readonly state
M.send_api = function(bufnr)
	local url = "https://api.openai.com/v1/chat/completions"
	local key = vim.env.OPENAI_API_KEY
	require("plenary.job")
		:new({
			command = "curl",
			args = {
				url,
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
					M.append_line_to_buffer(bufnr, "")
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

-- M.send_api(129)

return M

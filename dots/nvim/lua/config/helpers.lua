local M = {}

-- Directly sets keymaps for opening something in different window directions
-- Creates 6 keymaps: h (left), l (right), k (above), j (below), . (in place), , (new tab)
function M.make_directed_maps(prefix, command_desc, command, extra_opts)
	local directions = {
		{ key = "h", desc = "to left", cmd_prefix = "aboveleft vsplit" },
		{ key = "l", desc = "to right", cmd_prefix = "belowright vsplit" },
		{ key = "k", desc = "above", cmd_prefix = "aboveleft split" },
		{ key = "j", desc = "below", cmd_prefix = "belowright split" },
		{ key = ".", desc = "in place", cmd_prefix = nil },
		{ key = ",", desc = "in new tab", cmd_prefix = "tabnew" },
	}

	for _, d in ipairs(directions) do
		local full_desc = command_desc .. " " .. d.desc
		local full_cmd = d.cmd_prefix and string.format("<CMD>%s | %s<CR>", d.cmd_prefix, command)
			or string.format("<CMD>%s<CR>", command)

		local opts = extra_opts or {}
		opts.desc = full_desc
		vim.keymap.set("n", prefix .. d.key, full_cmd, opts)
	end
end

M.toggle_executable_bit = function(file_path)
	assert(type(file_path) == "string", "A valid file path must be provided.")
	vim.loop.fs_stat(file_path, function(err, stat)
		if err ~= nil or stat == nil then
			print(string.format("Error accessing %s: %s", file_path, err))
			return
		end
		local is_executable = bit.band(stat.mode, 0x48) ~= 0 -- 0x49 corresponds to 001 001 001 in binary

		local new_mode
		if is_executable then
			new_mode = bit.band(stat.mode, bit.bnot(0x48))
		else
			new_mode = bit.bor(stat.mode, 0x48)
		end

		vim.loop.fs_chmod(file_path, new_mode, function(chmod_err)
			if chmod_err then
				print(string.format("Error changing permissions of %s: %s", file_path, chmod_err))
			end
		end)
	end)
end

-- Runs a shell command asynchronously with callbacks
M.run_shell_command_async = function(opts)
	assert(type(opts.cmd) == "string", "cmd must be a string")

	local output = {}
	vim.fn.jobstart(opts.cmd, {
		on_stdout = function(_, data)
			if data then
				vim.list_extend(output, data)
			end
		end,
		on_stderr = function(_, data)
			if data then
				vim.list_extend(output, data)
			end
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				local output_str = table.concat(output, "\n")
				if exit_code == 0 then
					if opts.on_success then
						opts.on_success(output_str)
					end
				else
					if opts.on_error then
						opts.on_error(output_str, exit_code)
					end
				end
			end)
		end,
		stdout_buffered = true,
		stderr_buffered = true,
	})
end

-- Runs a git command asynchronously with automatic notifications and fugitive refresh
M.run_git_command_async = function(git_args)
	assert(type(git_args) == "string", "git_args must be a string")

	-- Extract action verb (first word) for messages
	local action = git_args:match("^(%S+)")

	vim.notify("Running git " .. action .. "...", vim.log.levels.INFO)

	M.run_shell_command_async({
		cmd = "git " .. git_args,
		on_success = function(output)
			vim.notify("Git " .. action .. " succeeded", vim.log.levels.INFO)
			vim.fn["FugitiveDidChange"]()
		end,
		on_error = function(output, exit_code)
			vim.notify("Git " .. action .. " failed:\n" .. output, vim.log.levels.ERROR)
		end,
	})
end

return M

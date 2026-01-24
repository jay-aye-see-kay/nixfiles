local M = {}

function M.merge(t1, t2)
	return vim.tbl_extend("force", t1, t2)
end

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

function M.exec(command)
	local file, err = io.popen(command, "r")
	if file == nil then
		print("file could not be opened:", err)
		return
	end
	local res = {}
	for line in file:lines() do
		table.insert(res, line)
	end
	return res
end

-- Simple wrapper for vim.keymap.set that ensures description is always set
function M.keymap(mode, lhs, rhs, desc, extraOpts)
	local opts = extraOpts or {}
	opts.desc = desc
	vim.keymap.set(mode, lhs, rhs, opts)
end

-- Legacy map function (kept for backward compatibility)
function M.map(mode, lhs, rhs, extraOpts)
	local opts = extraOpts or {}
	vim.keymap.set(mode, lhs, rhs, opts)
end

function M.buf_map(buffer, mode, lhs, rhs, extraOpts)
	local opts = extraOpts or {}
	opts.buffer = buffer
	vim.keymap.set(mode, lhs, rhs, opts)
end

M.cfg_augroup = vim.api.nvim_create_augroup("Main augroup for config", { clear = true })

M.autocmd = function(event, _opts)
	local opts = _opts or {}
	opts.group = M.cfg_augroup
	vim.api.nvim_create_autocmd(event, opts)
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

return M

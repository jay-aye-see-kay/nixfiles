local M = {}

function M.merge(t1, t2)
	return vim.tbl_extend("force", t1, t2)
end

function M.make_directed_maps(command_desc, command)
	local directions = {
		left = { key = "h", description = "to left", command_prefix = "aboveleft vsplit" },
		right = { key = "l", description = "to right", command_prefix = "belowright vsplit" },
		above = { key = "k", description = "above", command_prefix = "aboveleft split" },
		below = { key = "j", description = "below", command_prefix = "belowright split" },
		in_place = { key = ".", description = "in place", command_prefix = nil },
		tab = { key = ",", description = "in new tab", command_prefix = "tabnew" },
	}

	local maps = {}
	for _, d in pairs(directions) do
		local full_description = command_desc .. " " .. d.description
		local full_command = d.command_prefix -- approximating a ternary
				and "<CMD>" .. d.command_prefix .. " | " .. command .. "<CR>"
			or "<CMD>" .. command .. "<CR>"

		maps[d.key] = { full_command, full_description }
	end
	return maps
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

function M.map(mode, lhs, rhs, extraOpts)
	local opts = { noremap = true, silent = true }
	if extraOpts then
		opts = M.merge(opts, extraOpts)
	end
	vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
end

function M.buf_map(buffer, mode, lhs, rhs, extraOpts)
	local opts = { noremap = true, silent = true }
	if extraOpts then
		opts = M.merge(opts, extraOpts)
	end
	vim.api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
end

M.cfg_augroup = vim.api.nvim_create_augroup("Main augroup for config", { clear = true })

M.autocmd = function(event, _opts)
	local opts = _opts or {}
	opts.group = M.cfg_augroup
	vim.api.nvim_create_autocmd(event, opts)
end

return M

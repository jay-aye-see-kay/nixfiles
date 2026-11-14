-- Rex config, linked to ~/.config/rex/init.lua by modules/home-manager/rex.nix

-- Seamless ctrl+h/j/k/l between Rex panes and Neovim windows.
-- When nvim is in the foreground the key falls through to it, and smart-splits
-- (dots/nvim/lua/plugins/keymaps.lua) hands focus back to Rex at nvim's edge.
-- @see: https://github.com/rawnly/smart-splits-backend-rex#without-the-rex-module

local function is_vim(ctx)
	if not ctx.block_id then
		return false
	end
	local proc = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
	local fg = proc and proc.foreground
	if not fg then
		return false
	end
	-- `name` is not always the executable's name (e.g. a version string), so check argv0 too
	for _, s in ipairs({ fg.name or "", (fg.argv0 or ""):match("[^/]*$") }) do
		if s:match("^n?vim") then
			return true
		end
	end
	return false
end

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	rex.bind("ctrl+" .. key, function(ctx)
		if is_vim(ctx) then
			-- let the key through to nvim
			return false
		end
		rex.session.focus_direction({ direction = direction, wrap = false })
		return true
	end)
end

-- Scroll scrollback a page (ctrl+u/d plus shift, so the shell keeps ctrl+u/d).
rex.bind("ctrl+shift+u", "client.scroll.page_up")
rex.bind("ctrl+shift+d", "client.scroll.page_down")

-- ctrl+shift+n toggles a floating nvim on today's daily note (like <leader>nl in nvim).
-- It's one long-lived nvim found by its block label: shown/focused, hidden when
-- focused, and moved to the current window if it was floating in another one.
-- The nvim side (dots/nvim/lua/plugins/notes.lua) follows the date on focus.
local NOTES_LABEL = "notes"
local NOTES_BOUNDS = { 0.15, 0.1, 0.7, 0.8 }

local function find_notes(view)
	for _, w in ipairs(view.windows) do
		for _, l in ipairs(w.layers) do
			for _, b in ipairs(l.blocks) do
				if b.label == NOTES_LABEL then
					return { window = w, layer = l, block_id = b.block_id }
				end
			end
		end
	end
end

local function toggle_notes(ctx)
	local view = assert(rex.session.view({}))
	local notes = find_notes(view)

	if not notes then
		assert(rex.session.new_layer({
			bounds = NOTES_BOUNDS,
			focus = true,
			layout = {
				block = {
					flavor = "com.superlogical.terminal.shell",
					label = NOTES_LABEL,
					options = {
						cwd = os.getenv("HOME") .. "/obsidian/notes",
						command = { "nvim", "--cmd", "let g:logbook_follow_today = 1", "+LogbookToday" },
					},
				},
			},
		}))
		return true
	end

	local layer_id = notes.layer.layer_id
	local here = notes.window.window_id == view.active_window_id
	if not here then
		-- floating layers belong to a window, so bring the block over to this one
		local anchor = ctx.block_id
		for _, w in ipairs(view.windows) do
			if w.window_id == view.active_window_id then
				anchor = w.focused_block_id or anchor
			end
		end
		assert(rex.session.move_block({ block_id = notes.block_id, anchor_block_id = anchor }))
		layer_id = assert(rex.session.float_block({ block_id = notes.block_id, bounds = NOTES_BOUNDS })).layer_id
	elseif notes.layer.kind ~= "floating" then
		-- it was tiled into the layout by hand; float it again
		layer_id = assert(rex.session.float_block({ block_id = notes.block_id, bounds = NOTES_BOUNDS })).layer_id
	elseif notes.layer.state ~= "minimized" and notes.window.focused_block_id == notes.block_id then
		assert(rex.session.set_layer_state({ layer_id = layer_id, state = "minimized" }))
		return true
	end

	assert(rex.session.set_layer_state({ layer_id = layer_id, state = "normal", focus = true }))
	return true
end

rex.bind("ctrl+shift+n", toggle_notes)

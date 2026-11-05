-- Rex config, linked to ~/.config/rex/init.lua by users/jack/home.nix

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
-- Uncomment once client.scroll.* leaves Rex's Bleeding Edge channel; until then the app warns "unknown action".
-- rex.bind("ctrl+shift+u", "client.scroll.page_up")
-- rex.bind("ctrl+shift+d", "client.scroll.page_down")

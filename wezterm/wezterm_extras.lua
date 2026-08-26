local wezterm = require("wezterm")

local M = {}

function M.basename(s)
	s = string.gsub(s, "[/\\]+$", "") -- a cwd url can come with a trailing slash
	return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

function M.get_cwd(tab)
	local cwd = tab.active_pane.current_working_dir
	return cwd and M.basename(cwd.file_path) or "Overlay"
end

-- A pane sitting at one of these is considered idle: show its cwd instead.
-- login(1) is what macOS starts the shell through.
local idle_processes = {
	["bash"] = true,
	["fish"] = true,
	["login"] = true,
	["sh"] = true,
	["zsh"] = true,
}

--- Name to show for a running program, or nil for a bare shell prompt.
---@param path string? Executable path of the pane's foreground process.
local function program_name(path)
	-- Empty for panes we cannot introspect, e.g. remote mux panes.
	if not path or #path == 0 then
		return nil
	end

	local name = M.basename(path):gsub("%.exe$", ""):gsub("^%-", "")
	if idle_processes[name] then
		return nil
	end
	return name
end

-- Name of the program running in the tab's active pane, or nil when the pane is
-- just sitting at a shell prompt.
function M.get_process(tab)
	return program_name(tab.active_pane.foreground_process_name)
end

-- What a tab should be called: a title set on it wins (either typed by hand or
-- pushed by refresh_tab_titles below), then the program running in it, then the
-- directory it sits in.
function M.get_title(tab)
	if tab.tab_title and #tab.tab_title > 0 then
		return tab.tab_title
	end
	return M.get_process(tab) or M.get_cwd(tab)
end

-- Titles typed by hand (SUPER+r) have to survive the automatic naming below,
-- and a tab cannot tell one apart from a title we pushed ourselves, so remember
-- them here, keyed by tab id.
M.manual_titles = {}

-- Whether manual_titles has been reconciled with the tabs that already exist
local seeded = false

--- Record a hand-typed title for a tab, or with an empty line forget it and
--- hand the tab back to automatic naming.
function M.set_manual_title(tab, line)
	if line == "" then
		M.manual_titles[tab:tab_id()] = nil
	else
		M.manual_titles[tab:tab_id()] = line
	end
	tab:set_title(line)
end

-- Same as get_process/get_cwd, but reading a mux Pane rather than the
-- PaneInformation that format-tab-title is handed.
local function pane_title(pane)
	local cwd = pane:get_current_working_dir()
	return program_name(pane:get_foreground_process_name()) or (cwd and M.basename(cwd.file_path)) or "Overlay"
end

--- Name every tab in a window after the program running in it, falling back to
--- the directory. Driven from update-status, i.e. on a timer, because a pane's
--- foreground process changing is not something wezterm redraws the tab bar
--- for: waiting for format-tab-title to be called again leaves a finished
--- command in the title until some unrelated redraw happens to come along.
function M.refresh_tab_titles(window)
	for _, tab in ipairs(window:mux_window():tabs()) do
		local tab_id = tab:tab_id()
		local title = pane_title(tab:active_pane())

		-- Reloading the config loses manual_titles while the tabs live on in
		-- the mux, so on the first pass keep any title that is not one we would
		-- have set ourselves: it can only have been typed by hand.
		if not seeded then
			local existing = tab:get_title()
			if #existing > 0 and existing ~= title then
				M.manual_titles[tab_id] = existing
			end
		end

		-- Setting the title is what nudges the tab bar into rebuilding, so only
		-- do it when the title actually changed.
		if not M.manual_titles[tab_id] and tab:get_title() ~= title then
			tab:set_title(title)
		end
	end
	seeded = true
end

function M.is_neovim(pane)
	local process_name = M.basename(pane:get_foreground_process_name())
	return process_name == "nvim"
end

-- Merges the two provided key tables and returns a new table
function M.merge_keys(t1, t2)
	local result = {}
	for _, v in ipairs(t1) do
		table.insert(result, v)
	end
	for _, v in pairs(t2) do
		table.insert(result, v)
	end
	return result
end

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local resize_amount = 5

-- Bind resize functionality to either send the action to wezterm or neovim
local function resize_key(key)
	return {
		key = key,
		mods = "ALT",
		action = wezterm.action_callback(function(win, pane)
			if M.is_neovim(pane) then
				win:perform_action({ SendKey = { key = key, mods = "ALT" } }, pane)
			else
				win:perform_action({ AdjustPaneSize = { direction_keys[key], resize_amount } }, pane)
			end
		end),
	}
end

M.keys = {
	resize_key("h"),
	resize_key("j"),
	resize_key("k"),
	resize_key("l"),
}

return M

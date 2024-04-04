--- wezterm.lua
--- $ figlet -f small Wezterm
--- __      __      _
--- \ \    / /__ __| |_ ___ _ _ _ __
---  \ \/\/ / -_)_ /  _/ -_) '_| '  \
---   \_/\_/\___/__|\__\___|_| |_|_|_|
---
--- My Wezterm config file

local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "carbonfox"

config.font = wezterm.font("CaskaydiaMono Nerd Font")

config.initial_cols = 1000
config.initial_rows = 1000

config.font_size = 13
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.max_fps = 144

-- Alert bell
config.audible_bell = "Disabled"

config.colors = {
	visual_bell = "#4c566a",
}

config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
}

wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
	-- Define colors
	local colors = {
		edge_background = "#0b0022",
		background = "#1b1032",
		foreground = "#808080",
		active_background = "#2b2042",
		active_foreground = "#c0c0c0",
		hover_background = "#3b3052",
		hover_foreground = "#909090",
	}

	-- Determine foreground color based on tab state
	local foreground = colors.foreground
	if tab.is_active then
		foreground = colors.active_foreground
	elseif hover then
		foreground = colors.hover_foreground
	end

	-- Truncate title to fit max_width
	local title = wezterm.truncate_right(tab.active_pane.title, max_width - 2)

	-- Prepare title segments
	local segments = {
		{ Background = { Color = colors.edge_background } },
		{ Foreground = { Color = colors.background } },
		{ Text = wezterm.nerdfonts.pl_right_hard_divider }, -- SOLID_LEFT_ARROW
		{ Background = { Color = colors.background } },
		{ Foreground = { Color = foreground } },
		{ Text = title },
		{ Background = { Color = colors.background } },
		{ Foreground = { Color = colors.edge_background } },
		{ Text = wezterm.nerdfonts.pl_left_hard_divider }, -- SOLID_RIGHT_ARROW
	}

	return segments
end)

-- Keybindings
config.disable_default_key_bindings = true

config.keys = {
	-- Panes
	{
		key = "|",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "Enter",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "w",
		mods = "CTRL|SHIFT",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "LeftArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.AdjustPaneSize({ "Left", 1 }),
	},
	{
		key = "RightArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.AdjustPaneSize({ "Right", 1 }),
	},
	{
		key = "UpArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.AdjustPaneSize({ "Up", 1 }),
	},
	{
		key = "DownArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.AdjustPaneSize({ "Down", 1 }),
	},
	{
		key = "j",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},
	{
		key = "k",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		key = "h",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		key = "l",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Right"),
	},
	{
		key = "z",
		mods = "CTRL|SHIFT",
		action = wezterm.action.TogglePaneZoomState,
	},

	-- Quick Select
	{
		key = "Space",
		mods = "CTRL|SHIFT",
		action = wezterm.action.QuickSelect,
	},

	-- Activate copy mode
	{
		key = "x",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivateCopyMode,
	},

	-- Clipboard
	{
		key = "c",
		mods = "CMD",
		action = wezterm.action.CopyTo("Clipboard"),
	},
	{
		key = "v",
		mods = "CMD",
		action = wezterm.action.PasteFrom("Clipboard"),
	},

	-- Font size
	{
		key = "-",
		mods = "CTRL|SHIFT",
		action = wezterm.action.DecreaseFontSize,
	},
	{
		key = "+",
		mods = "CTRL|SHIFT",
		action = wezterm.action.IncreaseFontSize,
	},
	{
		key = "0",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ResetFontSize,
	},

	-- Tabs
	{
		key = "t",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "t",
		mods = "CTRL|SHIFT|ALT",
		action = wezterm.action.CloseCurrentTab({ confirm = true }),
	},
	{
		key = "Tab",
		mods = "CTRL",
		action = wezterm.action.ActivateTabRelative(1),
	},
	{
		key = "Tab",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivateTabRelative(-1),
	},
	{
		key = "1",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivateTab(0),
	},
	{
		key = "2",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivateTab(1),
	},
	{
		key = "3",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivateTab(2),
	},
	{
		key = "4",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivateTab(3),
	},
	{
		key = "5",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivateTab(4),
	},
	{
		key = "6",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivateTab(5),
	},
	{
		key = "7",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivateTab(6),
	},
	{
		key = "8",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivateTab(7),
	},
	{
		key = "9",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivateTab(7),
	},

	-- Search
	{
		key = "f",
		mods = "CTRL|SHIFT",
		action = wezterm.action.Search({ CaseSensitiveString = "" }),
	},

	-- Scrollback
	{
		key = "PageUp",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ScrollByPage(-1),
	},
	{
		key = "PageDown",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ScrollByPage(1),
	},
	{
		key = "Home",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ClearScrollback("ScrollbackOnly"),
	},
}

return config

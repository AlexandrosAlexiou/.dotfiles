local M = {}

---@type snacks.picker.layout.Config
local telecsope_layout = {
    reverse = true,
    layout = {
        box = "horizontal",
        backdrop = false,
        width = 0.975,
        height = 0.975,
        border = "none",
        {
            box = "vertical",
            { win = "list", title = " Results ", title_pos = "center", border = "rounded" },
            {
                win = "input",
                height = 1,
                border = "rounded",
                title = "{title} {live} {flags}",
                title_pos = "center",
            },
        },
        {
            win = "preview",
            title = "{preview:Preview}",
            border = "rounded",
            width = 0.5,
            title_pos = "center",
        },
    },
}

---@type table<string, snacks.picker.layout.Config>
local layouts = {
    default = telecsope_layout,
    telescope = telecsope_layout,
    vertical = {
        reverse = true,
        layout = {
            backdrop = false,
            width = 0.9,
            min_width = 80,
            height = 0.9,
            min_height = 30,
            box = "vertical",
            border = "rounded",
            title = "{title} {live} {flags}",
            title_pos = "center",
            { win = "preview", title = "{preview}", height = 0.7, border = "bottom" },
            { win = "list", border = "none" },
            { win = "input", height = 1, border = "top" },
        },
    },
}

---@type table<string, false|string|fun(self: snacks.win)|snacks.win.Keys>
local common_keys = {
    ["<C-q>"] = { "close", mode = { "n", "i" } },
    ["<C-d>"] = { "preview_scroll_down", mode = { "n", "i" } },
    ["<C-u>"] = { "preview_scroll_up", mode = { "n", "i" } },
    ["<C-l>"] = { "preview_scroll_right", mode = { "n", "i" } },
    ["<C-h>"] = { "preview_scroll_left", mode = { "n", "i" } },
    ["g?"] = { "toggle_help_list", mode = { "n", "i" } },
    ["?"] = { "toggle_preview", mode = { "n", "i" } },
}

---@type snacks.picker.Config|{}
M.picker = {
    layouts = layouts,
    actions = {
        trouble_open = function(...)
            return require("trouble.sources.snacks").actions.trouble_open.action(...)
        end,
    },
    win = {
        input = {
            keys = vim.tbl_extend("force", common_keys, {
                ["<C-c>"] = { "trouble_open", mode = { "n", "i" } },
            }),
        },
        list = {
            keys = common_keys,
        },
        preview = {
            wo = {
                wrap = false,
            },
        },
    },
    formatters = {
        file = {
            filename_first = true,
        },
    },
    sources = {
        pickers = {
            layout = {
                preset = "vscode",
            },
        },
        grep = {
            follow = true,
        },
        explorer = {
            layout = {
                preset = "sidebar",
                preview = "main",
                hidden = { "preview" },
            },
            win = {
                list = {
                    keys = {
                        ["<Esc>"] = { "" },
                        ["-"] = "explorer_up",
                        ["o"] = "confirm",
                        ["="] = "confirm",
                        ["+"] = "confirm",
                        ["O"] = "explorer_open",
                        ["?"] = "toggle_help_list",
                        ["<C-t>"] = "tab",
                        ["<M-h>"] = false,
                    },
                },
            },
        },
        keymaps = {
            layout = {
                preset = "ivy",
                hidden = { "preview" },
            },
        },
        help = { layout = { preset = "vertical" } },
        colorschemes = { layout = { preset = "vertical" } },
        notifications = { layout = { preset = "vertical" } },
    },
}

return M

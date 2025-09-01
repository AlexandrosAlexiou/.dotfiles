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
    ["<C-v>"] = { "edit_vsplit", mode = { "n", "i" } },
    ["<C-x>"] = { "edit_split", mode = { "n", "i" } },
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
        cycle_preview = function(...)
            require("tt._plugins.snacks.actions").cycle_preview(...)
        end,
    },
    win = {
        input = {
            keys = vim.tbl_extend("force", common_keys, {
                ["<C-c>"] = { "trouble_open", mode = { "n", "i" } },
                ["<C-p>"] = { "cycle_preview", mode = { "n", "i" } },
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
        files = {
            actions = {
                switch_grep = function(picker)
                    require("tt._plugins.snacks.actions").reopen_picker(
                        picker,
                        "grep",
                        { search = picker:filter().pattern }
                    )
                end,
            },
            win = {
                input = {
                    keys = {
                        ["<M-g>"] = { "switch_grep", mode = { "n", "i" } },
                    },
                },
            },
        },
        grep = {
            follow = true,
            actions = {
                switch_files = function(picker)
                    require("tt._plugins.snacks.actions").reopen_picker(
                        picker,
                        "files",
                        { pattern = picker:filter().search }
                    )
                end,
            },
            win = {
                input = {
                    keys = {
                        ["<M-g>"] = { "switch_files", mode = { "n", "i" } },
                    },
                },
            },
        },
        pickers = {
            layout = {
                preset = "vscode",
            },
        },
        buffers = {
            win = {
                input = {
                    keys = {
                        ["dd"] = { "bufdelete", mode = "n" },
                    },
                },
            },
        },
        explorer = require("tt._plugins.snacks.explorer").explorer,
        keymaps = {
            layout = {
                preset = "ivy",
                hidden = { "preview" },
            },
        },
        lines = {
            layout = {
                preset = "vertical",
                hidden = { "preview" },
                layout = { height = 0.85, width = 0.85 },
            },
        },
        help = { layout = { preset = "vertical" } },
        colorschemes = { layout = { preset = "vertical" } },
        notifications = { layout = { preset = "vertical" } },
    },
}

return M

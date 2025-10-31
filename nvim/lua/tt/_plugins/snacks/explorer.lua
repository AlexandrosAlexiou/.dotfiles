local Actions = require "snacks.explorer.actions"
local Tree = require "snacks.explorer.tree"

local M = {}

---Source code adapted from: https://github.com/folke/snacks.nvim/discussions/1306#discussioncomment-12248922
---@type snacks.picker.Config
M.explorer = {
    layout = {
        preview = "main",
        layout = {
            backdrop = false,
            width = 80,
            min_width = 40,
            height = 0.5, -- Vertical size: 80% of screen height (or use absolute number like 50 for 50 lines)
            position = "left",
            box = "vertical",
            { win = "input", height = 1 }, -- Search input at top
            { win = "list", border = "none" }, -- File list below input
        },
    },
    on_show = function(picker)
        local window_gap = 1

        local root = picker.layout.root

        ---@param win snacks.win
        local update = function(win)
            win.opts.row = vim.api.nvim_win_get_position(root.win)[1]
            win.opts.col = vim.api.nvim_win_get_width(root.win) + window_gap
            win.opts.height = 0.85
            win.opts.width = 0.5
            win:update()
        end

        local preview_win = Snacks.win.new {
            relative = "editor",
            external = false,
            focusable = false,
            border = "rounded",
            backdrop = false,
            show = false,
            bo = {
                filetype = "snacks_float_preview",
                buftype = "nofile",
                buflisted = false,
                swapfile = false,
                undofile = false,
            },
            on_win = function(win)
                update(win)
                picker:show_preview()
            end,
        }

        picker.preview.win = preview_win

        root:on("WinResized", function()
            update(preview_win)
        end)
    end,
    actions = {
        toggle_preview = function(picker)
            picker.preview.win:toggle()
        end,
        scroll_down = function(picker)
            if picker.list and picker.list.win and picker.list.win.win then
                local height = vim.api.nvim_win_get_height(picker.list.win.win)
                local scroll_amount = math.floor(height / 7)
                for _ = 1, scroll_amount do
                    picker:action "list_down"
                end
            end
        end,
        scroll_up = function(picker)
            if picker.list and picker.list.win and picker.list.win.win then
                local height = vim.api.nvim_win_get_height(picker.list.win.win)
                local scroll_amount = math.floor(height / 7)
                for _ = 1, scroll_amount do
                    picker:action "list_up"
                end
            end
        end,
        expand_recursive = function(picker, item)
            local item_node = Tree:node(item.file)
            if not item_node then
                return
            end

            Tree:walk(item_node, function(node)
                if node.dir then
                    Tree:open(node.path)
                    Tree:expand(node)
                end
            end, { all = true })

            Actions.update(picker, { refresh = true })
        end,
        collapse_recursive = function(picker, item)
            local item_node = Tree:node(item.file)
            if not item_node then
                return
            end

            Tree:walk(item_node, function(node)
                if node.dir then
                    Tree:close(node.path)
                end
            end, { all = true })

            Actions.update(picker, { refresh = true })
        end,
    },
    win = {
        list = {
            keys = {
                ["-"] = "explorer_up",
                ["o"] = "confirm",
                ["="] = "confirm",
                ["+"] = "confirm",
                ["O"] = "explorer_open",
                ["?"] = "toggle_help_list",
                ["L"] = "expand_recursive",
                ["H"] = "collapse_recursive",
                ["<C-t>"] = "tab",
                ["<C-f>"] = "focus_input",
                ["<M-h>"] = false,
                ["<C-u>"] = "scroll_up", -- Scroll up with Ctrl+u
                ["<C-d>"] = "scroll_down", -- Scroll down with Ctrl+d
            },
        },
    },
}

return M

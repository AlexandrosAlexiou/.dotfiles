local utils = require "tt.utils"
local state = require "tt._plugins.snacks.terminal.state"
local win = require "tt._plugins.snacks.terminal.window"
local layout = require "tt._plugins.snacks.terminal.layout"

local M = {}

---@type snacks.terminal.Config|{}
M.terminal = {
    win = {
        keys = {
            term_normal = {
                "<esc>",
                function()
                    -- Let lazygit (and other TUIs that need <esc>) handle the key themselves.
                    local st = vim.b.snacks_terminal
                    local cmd = st and st.cmd
                    if type(cmd) == "table" then
                        cmd = cmd[1]
                    end
                    if type(cmd) == "string" and cmd:match "lazygit" then
                        return "<esc>"
                    end
                    return "<C-\\><C-n>"
                end,
                mode = "t",
                expr = true,
                replace_keycodes = true,
                desc = "Escape terminal mode",
            },
            hide_esc = {
                "<C-/>",
                function(self)
                    vim.cmd.stopinsert()
                    self:hide()
                end,
                mode = { "n", "t" },
                desc = "Hide terminal",
            },
            nav_h = { "<C-h>", function() vim.cmd.wincmd "h" end, mode = { "n", "t" }, desc = "Go to left window" },
            nav_j = { "<C-j>", function() vim.cmd.wincmd "j" end, mode = { "n", "t" }, desc = "Go to lower window" },
            nav_k = { "<C-k>", function() vim.cmd.wincmd "k" end, mode = { "n", "t" }, desc = "Go to upper window" },
            nav_l = { "<C-l>", function() vim.cmd.wincmd "l" end, mode = { "n", "t" }, desc = "Go to right window" },
        },
    },
}

---Create a new split terminal at the given position.
---@param position tt.terminal.Position Where to anchor the new split
---@return nil
local function create_terminal(position)
    local vertical = position == "right"
    local orientation = vertical and "vertical" or "horizontal"
    local marker = "snacks_terminal_" .. orientation
    local dim = vertical and "width" or "height"

    state.next_count[orientation] = state.next_count[orientation] + 1
    local count = state.next_count[orientation]
    local key = orientation .. ":" .. count

    state.creation_seq = state.creation_seq + 1
    state.registry[key] = { orientation = orientation, count = count, position = position, seq = state.creation_seq }
    state.last_terminal_key = key

    local lr = vim.o.lazyredraw
    vim.o.lazyredraw = true
    local ea = vim.o.equalalways
    vim.o.equalalways = false

    for _, w in ipairs(win.all_terminal_windows()) do
        if vim.api.nvim_win_is_valid(w) then
            vim.wo[w].winfixwidth = false
            vim.wo[w].winfixheight = false
        end
    end

    Snacks.terminal.toggle(nil, {
        count = count,
        env = { [marker] = "1" },
        win = {
            position = position,
            relative = "win",
            [dim] = 0.5,
            wo = { winhighlight = "Normal:Normal,NormalNC:Normal" },
        },
    })

    win.defuse_snacks_equalize()
    layout.equalize_terminals()
    layout.equalize_terminals()

    vim.o.equalalways = ea
    vim.o.lazyredraw = lr
    vim.cmd "redraw"
end

---Toggle a specific terminal by its registry key.
---@param key tt.terminal.Key Terminal key ("orientation:count")
---@return nil
local function toggle_terminal(key)
    local cfg = state.registry[key]
    if not cfg then
        return
    end
    local marker = "snacks_terminal_" .. cfg.orientation
    local was_visible = win.find_terminal_window(cfg.orientation, cfg.count) ~= nil

    local lr = vim.o.lazyredraw
    vim.o.lazyredraw = true
    local ea = vim.o.equalalways
    vim.o.equalalways = false

    if was_visible then
        state.restoring = true
        Snacks.terminal.toggle(nil, {
            count = cfg.count,
            env = { [marker] = "1" },
        })
        state.restoring = false
    else
        local t = win.find_snacks_terminal_obj(cfg.orientation, cfg.count)
        if t then
            t.opts.win = vim.api.nvim_get_current_win()
            t:toggle()
        else
            Snacks.terminal.toggle(nil, {
                count = cfg.count,
                env = { [marker] = "1" },
            })
        end
    end

    win.defuse_snacks_equalize()

    if was_visible then
        vim.o.equalalways = ea
        vim.o.lazyredraw = lr
        vim.cmd.stopinsert()
    else
        layout.restore_layout()
        layout.restore_layout()
        vim.o.equalalways = ea
        vim.o.lazyredraw = lr
        vim.cmd "redraw"
        local snap = state.saved_layout
        vim.schedule(function()
            state.restoring = true
            state.saved_layout = snap
            layout.restore_layout()
            state.restoring = false
        end)
    end
end

---Toggle every managed split terminal (hide all if any visible, else restore).
---@return nil
local function toggle_all_terminals()
    local vis = win.visible_terminal_keys()
    local lr = vim.o.lazyredraw
    vim.o.lazyredraw = true

    if #vis > 0 then
        state.restore_snapshot = vis
        state.restoring = true
        local ea = vim.o.equalalways
        vim.o.equalalways = false
        for _, key in ipairs(vis) do
            local cfg = state.registry[key]
            if cfg then
                local marker = "snacks_terminal_" .. cfg.orientation
                Snacks.terminal.toggle(nil, {
                    count = cfg.count,
                    env = { [marker] = "1" },
                })
            end
        end
        vim.o.equalalways = ea
        state.restoring = false
        vim.o.lazyredraw = lr
        vim.cmd.stopinsert()
        return
    end

    -- Restore: sort by creation order for correct tree rebuild
    local ordered = vim.deepcopy(state.restore_snapshot)
    table.sort(ordered, function(a, b)
        local sa = state.registry[a] and state.registry[a].seq or 0
        local sb = state.registry[b] and state.registry[b].seq or 0
        return sa < sb
    end)

    local ea = vim.o.equalalways
    vim.o.equalalways = false
    state.restoring = true

    -- Focus a non-terminal window so splits land correctly
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_is_valid(w) then
            local buf = vim.api.nvim_win_get_buf(w)
            if not vim.b[buf].snacks_terminal then
                vim.api.nvim_set_current_win(w)
                break
            end
        end
    end

    for _, key in ipairs(ordered) do
        local cfg = state.registry[key]
        if cfg then
            for _, w in ipairs(win.all_terminal_windows()) do
                if vim.api.nvim_win_is_valid(w) then
                    vim.wo[w].winfixwidth = false
                    vim.wo[w].winfixheight = false
                end
            end

            local marker = "snacks_terminal_" .. cfg.orientation
            local cur_win = vim.api.nvim_get_current_win()
            local t = win.find_snacks_terminal_obj(cfg.orientation, cfg.count)
            if t then
                t.opts.win = cur_win
                t:toggle()
            else
                Snacks.terminal.toggle(nil, {
                    count = cfg.count,
                    env = { [marker] = "1" },
                })
            end
            win.defuse_snacks_equalize()
        end
    end

    layout.restore_layout()
    layout.restore_layout()
    state.restoring = false
    vim.o.equalalways = ea
    vim.o.lazyredraw = lr
    vim.cmd "redraw"

    local snap = state.saved_layout
    vim.schedule(function()
        state.restoring = true
        state.saved_layout = snap
        layout.restore_layout()
        state.restoring = false
    end)
end

---Hide all visible terminals (stashes them for restore).
---@return nil
function M.hide_all()
    local vis = win.visible_terminal_keys()
    if #vis == 0 then
        return
    end
    state.restore_snapshot = vis
    state.restoring = true
    local ea = vim.o.equalalways
    vim.o.equalalways = false
    for _, key in ipairs(vis) do
        local cfg = state.registry[key]
        if cfg then
            local marker = "snacks_terminal_" .. cfg.orientation
            Snacks.terminal.toggle(nil, {
                count = cfg.count,
                env = { [marker] = "1" },
            })
        end
    end
    vim.o.equalalways = ea
    state.restoring = false
end

---Register autocmds and keymaps for the split terminal system.
---@return nil
function M.setup()
    -- Layout persistence autocmds
    local group = vim.api.nvim_create_augroup("tt_snacks_terminal_size", { clear = true })
    vim.api.nvim_create_autocmd({ "WinResized", "WinLeave" }, {
        group = group,
        desc = "Persist snacks terminal layout proportions",
        callback = layout.capture_layout,
    })

    -- Last-terminal tracking
    local track_group = vim.api.nvim_create_augroup("tt_terminal_tracking", { clear = true })
    vim.api.nvim_create_autocmd("BufEnter", {
        group = track_group,
        desc = "Track last active terminal for <leader>tt",
        callback = function(ev)
            local t = vim.b[ev.buf].snacks_terminal
            if t and type(t) == "table" and type(t.env) == "table" then
                local orientation
                if t.env.snacks_terminal_vertical then
                    orientation = "vertical"
                elseif t.env.snacks_terminal_horizontal then
                    orientation = "horizontal"
                end
                if orientation then
                    state.last_terminal_key = orientation .. ":" .. (t.id or 1)
                end
            end
        end,
    })

    -- Keymaps
    utils.map({ "n", "t" }, "<leader>ft", function()
        Snacks.terminal.toggle(nil, {
            env = { snacks_terminal_float = "1" },
            win = {
                border = "rounded",
                position = "float",
                height = 0.99,
                width = 0.99,
            },
        })
    end, { desc = "Toggle float terminal" })

    utils.map({ "n", "t" }, "<leader>ht", function()
        create_terminal "bottom"
    end, { desc = "New horizontal terminal" })

    utils.map({ "n", "t" }, "<leader>vt", function()
        create_terminal "right"
    end, { desc = "New vertical terminal" })

    utils.map({ "n", "t" }, "<leader>tt", function()
        if state.last_terminal_key then
            toggle_terminal(state.last_terminal_key)
        else
            Snacks.notify.warn "No terminal to toggle"
        end
    end, { desc = "Toggle last terminal" })

    utils.map({ "n", "t" }, "<leader>`", toggle_all_terminals, { desc = "Toggle all terminals" })

    utils.map({ "n", "t" }, "<leader>bt", function()
        Snacks.terminal.toggle("btop", {
            win = { height = 0.85, width = 0.85 },
        })
    end, { desc = "Toggle btop terminal" })
end

return M

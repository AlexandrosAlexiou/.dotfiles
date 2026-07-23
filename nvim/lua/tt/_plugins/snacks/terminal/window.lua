local state = require "tt._plugins.snacks.terminal.state"

local M = {}

---Find the window handle for a specific terminal by orientation and count.
---@param orientation tt.terminal.Orientation
---@param count integer 1-based per-orientation Snacks terminal id
---@return integer|nil win Window handle from `nvim_tabpage_list_wins`, or nil
function M.find_terminal_window(orientation, count)
    local marker = "snacks_terminal_" .. orientation
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_is_valid(win) then
            local t = vim.b[vim.api.nvim_win_get_buf(win)].snacks_terminal
            if t and type(t) == "table" and type(t.env) == "table" and t.env[marker] and (t.id or 1) == count then
                return win
            end
        end
    end
    return nil
end

---Find the Snacks terminal object by scanning all known terminals.
---More reliable than Snacks.terminal.get() which can fail if cwd changed.
---@param orientation tt.terminal.Orientation
---@param count integer 1-based per-orientation Snacks terminal id
---@return snacks.win|nil terminal Snacks terminal (window) object, or nil
function M.find_snacks_terminal_obj(orientation, count)
    local marker = "snacks_terminal_" .. orientation
    for _, t in ipairs(Snacks.terminal.list()) do
        if t.buf and vim.api.nvim_buf_is_valid(t.buf) then
            local bt = vim.b[t.buf].snacks_terminal
            if bt and type(bt) == "table" and type(bt.env) == "table" and bt.env[marker] and (bt.id or 1) == count then
                return t
            end
        end
    end
    return nil
end

---Collect ALL visible terminal windows (both orientations).
---@return integer[] wins Window handles of every managed split terminal on the current tabpage
function M.all_terminal_windows()
    local wins = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_is_valid(win) then
            local t = vim.b[vim.api.nvim_win_get_buf(win)].snacks_terminal
            if
                t
                and type(t) == "table"
                and type(t.env) == "table"
                and (t.env.snacks_terminal_vertical or t.env.snacks_terminal_horizontal)
            then
                wins[#wins + 1] = win
            end
        end
    end
    return wins
end

---Collect visible terminal keys from the current tabpage.
---Registers unknown terminals discovered during the scan.
---@return tt.terminal.Key[] keys Ordered list of "orientation:count" keys currently visible
function M.visible_terminal_keys()
    ---@type tt.terminal.Key[]
    local keys = {}
    ---@type table<tt.terminal.Key, boolean>
    local seen = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if not vim.api.nvim_win_is_valid(win) then
            goto skip
        end
        local t = vim.b[vim.api.nvim_win_get_buf(win)].snacks_terminal
        if t and type(t) == "table" and type(t.env) == "table" then
            ---@type tt.terminal.Orientation|nil
            local orientation
            if t.env.snacks_terminal_vertical then
                orientation = "vertical"
            elseif t.env.snacks_terminal_horizontal then
                orientation = "horizontal"
            end
            if orientation then
                local key = orientation .. ":" .. (t.id or 1)
                if not seen[key] then
                    seen[key] = true
                    keys[#keys + 1] = key
                    if not state.registry[key] then
                        state.creation_seq = state.creation_seq + 1
                        state.registry[key] = {
                            orientation = orientation,
                            count = t.id or 1,
                            position = orientation == "vertical" and "right" or "bottom",
                            seq = state.creation_seq,
                        }
                    end
                end
            end
        end
        ::skip::
    end
    return keys
end

---Build a map from window-id to terminal key ("vertical:1", etc.)
---@return table<integer, tt.terminal.Key> map Window handle → terminal key
function M.build_term_map()
    ---@type table<integer, tt.terminal.Key>
    local map = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if not vim.api.nvim_win_is_valid(win) then
            goto skip
        end
        local t = vim.b[vim.api.nvim_win_get_buf(win)].snacks_terminal
        if t and type(t) == "table" and type(t.env) == "table" then
            ---@type tt.terminal.Orientation|nil
            local orientation
            if t.env.snacks_terminal_vertical then
                orientation = "vertical"
            elseif t.env.snacks_terminal_horizontal then
                orientation = "horizontal"
            end
            if orientation then
                map[win] = orientation .. ":" .. (t.id or 1)
            end
        end
        ::skip::
    end
    return map
end

---Prevent Snacks' built-in equalize from grouping unrelated terminals.
---Gives each managed terminal a unique position tag.
---@return nil
function M.defuse_snacks_equalize()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if not vim.api.nvim_win_is_valid(win) then
            goto continue
        end
        local buf = vim.api.nvim_win_get_buf(win)
        local t = vim.b[buf].snacks_terminal
        if t and type(t) == "table" and type(t.env) == "table" then
            ---@type tt.terminal.Orientation|nil
            local orientation
            if t.env.snacks_terminal_vertical then
                orientation = "vertical"
            elseif t.env.snacks_terminal_horizontal then
                orientation = "horizontal"
            end
            if orientation then
                local sw = vim.w[win].snacks_win
                if sw and type(sw) == "table" then
                    sw.position = orientation .. "_" .. (t.id or 0)
                    vim.w[win].snacks_win = sw
                end
            end
        end
        ::continue::
    end
end

return M

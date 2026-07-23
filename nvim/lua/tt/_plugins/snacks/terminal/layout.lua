local state = require "tt._plugins.snacks.terminal.state"
local win = require "tt._plugins.snacks.terminal.window"

---@alias tt.terminal.WinLayoutDir "row"|"col"

---Layout tree node returned by `vim.fn.winlayout()`.
---Shape is one of:
---  - Leaf:   `{ "leaf", winid: integer }`
---  - Branch: `{ "row"|"col", children: tt.terminal.WinLayoutNode[] }`
---Typed as plain `table` because LuaLS cannot narrow the tuple union on `node[1]`.
---@alias tt.terminal.WinLayoutNode table

---@alias tt.terminal.TermSet table<integer, boolean>          # window handle → present
---@alias tt.terminal.TermMap table<integer, tt.terminal.Key>  # window handle → "orientation:count"

local M = {}

---Count terminal leaf windows inside a layout-tree node.
---@param node tt.terminal.WinLayoutNode Layout tree node from `vim.fn.winlayout()`
---@param term_set tt.terminal.TermSet Set of terminal window handles
---@return integer count Number of terminal leaves in the subtree
local function count_term_leaves(node, term_set)
    if node[1] == "leaf" then
        return term_set[node[2]] and 1 or 0
    end
    local n = 0
    for _, child in ipairs(node[2]) do
        n = n + count_term_leaves(child, term_set)
    end
    return n
end

---Count visual columns for width distribution.
---A leaf or vertical stack ("col") = 1 column; a row = sum of children's columns.
---@param node tt.terminal.WinLayoutNode
---@param term_set tt.terminal.TermSet
---@return integer columns Column units contributed by this subtree
local function column_units(node, term_set)
    if node[1] == "leaf" then
        return term_set[node[2]] and 1 or 0
    end
    if count_term_leaves(node, term_set) == 0 then
        return 0
    end
    if node[1] == "col" then
        return 1
    end
    local total = 0
    for _, child in ipairs(node[2]) do
        total = total + column_units(child, term_set)
    end
    return total
end

---Count visual rows for height distribution.
---A leaf or horizontal row ("row") = 1 row; a col = sum of children's rows.
---@param node tt.terminal.WinLayoutNode
---@param term_set tt.terminal.TermSet
---@return integer rows Row units contributed by this subtree
local function row_units(node, term_set)
    if node[1] == "leaf" then
        return term_set[node[2]] and 1 or 0
    end
    if count_term_leaves(node, term_set) == 0 then
        return 0
    end
    if node[1] == "row" then
        return 1
    end
    local total = 0
    for _, child in ipairs(node[2]) do
        total = total + row_units(child, term_set)
    end
    return total
end

---Return the first leaf window-id in a subtree.
---@param node tt.terminal.WinLayoutNode
---@return integer|nil win Window handle of the first descendant leaf, or nil
local function first_leaf_win(node)
    if node[1] == "leaf" then
        return node[2]
    end
    return first_leaf_win(node[2][1])
end

---Compute total width of a layout subtree (leaves + separators).
---@param node tt.terminal.WinLayoutNode
---@return integer width Combined width in screen cells, including vertical separators
local function subtree_width(node)
    if node[1] == "leaf" then
        return vim.api.nvim_win_is_valid(node[2]) and vim.api.nvim_win_get_width(node[2]) or 0
    end
    if node[1] == "row" then
        local total = 0
        for i, child in ipairs(node[2]) do
            total = total + subtree_width(child)
            if i < #node[2] then
                total = total + 1
            end
        end
        return total
    end
    local mx = 0
    for _, child in ipairs(node[2]) do
        mx = math.max(mx, subtree_width(child))
    end
    return mx
end

---Compute total height of a layout subtree (leaves + statuslines).
---@param node tt.terminal.WinLayoutNode
---@return integer height Combined height in screen cells, including status lines
local function subtree_height(node)
    if node[1] == "leaf" then
        return vim.api.nvim_win_is_valid(node[2]) and vim.api.nvim_win_get_height(node[2]) or 0
    end
    if node[1] == "col" then
        local total = 0
        for i, child in ipairs(node[2]) do
            total = total + subtree_height(child)
            if i < #node[2] then
                total = total + 1
            end
        end
        return total
    end
    local mx = 0
    for _, child in ipairs(node[2]) do
        mx = math.max(mx, subtree_height(child))
    end
    return mx
end

---Walk the layout tree and equalize terminal windows proportionally.
---@param node tt.terminal.WinLayoutNode Layout tree node
---@param term_set tt.terminal.TermSet
---@return nil
local function equalize_node(node, term_set)
    if node[1] == "leaf" then
        return
    end

    local dir = node[1]
    local children = node[2]

    local infos = {}
    for _, child in ipairs(children) do
        if count_term_leaves(child, term_set) > 0 then
            infos[#infos + 1] = { node = child }
        end
    end

    if #infos >= 2 then
        if dir == "row" then
            local total_w, total_units = 0, 0
            for _, info in ipairs(infos) do
                info.w = subtree_width(info.node)
                info.units = column_units(info.node, term_set)
                total_w = total_w + info.w
                total_units = total_units + info.units
            end
            if total_units > 0 then
                for i = 1, #infos - 1 do
                    local target = math.max(10, math.floor(total_w * infos[i].units / total_units))
                    local w = first_leaf_win(infos[i].node)
                    if w and vim.api.nvim_win_is_valid(w) then
                        vim.wo[w].winfixwidth = false
                        vim.api.nvim_win_set_width(w, target)
                    end
                end
            end
        else
            local total_h, total_units = 0, 0
            for _, info in ipairs(infos) do
                info.h = subtree_height(info.node)
                info.units = row_units(info.node, term_set)
                total_h = total_h + info.h
                total_units = total_units + info.units
            end
            if total_units > 0 then
                for i = 1, #infos - 1 do
                    local target = math.max(4, math.floor(total_h * infos[i].units / total_units))
                    local w = first_leaf_win(infos[i].node)
                    if w and vim.api.nvim_win_is_valid(w) then
                        vim.wo[w].winfixheight = false
                        vim.api.nvim_win_set_height(w, target)
                    end
                end
            end
        end
    end

    for _, child in ipairs(children) do
        equalize_node(child, term_set)
    end
end

---Equalize all terminal windows by walking the layout tree.
---@return nil
function M.equalize_terminals()
    local wins = win.all_terminal_windows()
    if #wins < 2 then
        return
    end
    ---@type tt.terminal.TermSet
    local term_set = {}
    for _, w in ipairs(wins) do
        term_set[w] = true
    end
    for _, w in ipairs(wins) do
        if vim.api.nvim_win_is_valid(w) then
            vim.wo[w].winfixwidth = false
            vim.wo[w].winfixheight = false
        end
    end
    equalize_node(vim.fn.winlayout(), term_set)
end

---Recursively collect sorted terminal keys from a layout subtree.
---@param node tt.terminal.WinLayoutNode
---@param term_map tt.terminal.TermMap
---@return tt.terminal.Key[] keys Sorted list of terminal keys found in the subtree
local function collect_term_keys(node, term_map)
    if node[1] == "leaf" then
        local key = term_map[node[2]]
        return key and { key } or {}
    end
    local keys = {}
    for _, child in ipairs(node[2]) do
        for _, k in ipairs(collect_term_keys(child, term_map)) do
            keys[#keys + 1] = k
        end
    end
    table.sort(keys)
    return keys
end

---Capture proportional layout as a tree snapshot.
---@param node tt.terminal.WinLayoutNode
---@param term_map tt.terminal.TermMap
---@return tt.terminal.LayoutSnapshot|nil snapshot Snapshot of the subtree, or nil if no terminals found
local function snapshot_node(node, term_map)
    if node[1] == "leaf" then
        return nil
    end

    local dir = node[1]
    local children = node[2]

    local term_infos = {}
    for _, child in ipairs(children) do
        local keys = collect_term_keys(child, term_map)
        if #keys > 0 then
            local size = dir == "row" and subtree_width(child) or subtree_height(child)
            term_infos[#term_infos + 1] = {
                keys_id = table.concat(keys, ","),
                size = size,
                child = child,
            }
        end
    end

    -- Single branch: save the edge size (editor-to-terminal boundary)
    if #term_infos == 1 then
        local info = term_infos[1]
        return {
            type = "edge",
            dir = dir,
            keys_id = info.keys_id,
            size = info.size,
            sub = snapshot_node(info.child, term_map),
        }
    end

    if #term_infos == 0 then
        return nil
    end

    -- Multiple branches: save fractional sizes
    local total = 0
    for _, info in ipairs(term_infos) do
        total = total + info.size
    end

    local snap = { type = "split", dir = dir, children = {} }
    for _, info in ipairs(term_infos) do
        snap.children[#snap.children + 1] = {
            keys_id = info.keys_id,
            fraction = total > 0 and info.size / total or 1 / #term_infos,
            sub = snapshot_node(info.child, term_map),
        }
    end
    return snap
end

---Capture a full layout snapshot of all terminal windows.
---@return tt.terminal.LayoutSnapshot|nil snapshot Root snapshot, or nil if no terminals
function M.snapshot_layout()
    local term_map = win.build_term_map()
    if vim.tbl_isempty(term_map) then
        return nil
    end
    return snapshot_node(vim.fn.winlayout(), term_map)
end

---Collect all terminal keys mentioned in a snapshot.
---@param snap tt.terminal.LayoutSnapshot|nil
---@return table<tt.terminal.Key, boolean> keys Set of terminal keys referenced in the snapshot
local function all_snapshot_keys(snap)
    ---@type table<tt.terminal.Key, boolean>
    local keys = {}
    if not snap then
        return keys
    end

    if snap.type == "edge" then
        for k in snap.keys_id:gmatch "[^,]+" do
            keys[k] = true
        end
        if snap.sub then
            for k in pairs(all_snapshot_keys(snap.sub)) do
                keys[k] = true
            end
        end
        return keys
    end

    if not snap.children then
        return keys
    end
    for _, child in ipairs(snap.children) do
        for k in child.keys_id:gmatch "[^,]+" do
            keys[k] = true
        end
        if child.sub then
            for k in pairs(all_snapshot_keys(child.sub)) do
                keys[k] = true
            end
        end
    end
    return keys
end

---Apply a saved snapshot to the current window tree.
---@param node tt.terminal.WinLayoutNode
---@param term_map tt.terminal.TermMap
---@param snap tt.terminal.LayoutSnapshot|nil
---@return nil
local function restore_node(node, term_map, snap)
    if not snap or node[1] == "leaf" then
        return
    end

    local dir = node[1]
    local children = node[2]

    local term_infos = {}
    for _, child in ipairs(children) do
        local keys = collect_term_keys(child, term_map)
        if #keys > 0 then
            term_infos[#term_infos + 1] = {
                keys_id = table.concat(keys, ","),
                child = child,
            }
        end
    end

    if snap.type == "edge" then
        if #term_infos == 1 and dir == snap.dir then
            local info = term_infos[1]
            local w = first_leaf_win(info.child)
            if w and vim.api.nvim_win_is_valid(w) then
                if dir == "col" then
                    vim.wo[w].winfixheight = false
                    vim.api.nvim_win_set_height(w, snap.size)
                else
                    vim.wo[w].winfixwidth = false
                    vim.api.nvim_win_set_width(w, snap.size)
                end
            end
            if snap.sub then
                restore_node(info.child, term_map, snap.sub)
            end
        elseif snap.sub then
            for _, info in ipairs(term_infos) do
                restore_node(info.child, term_map, snap.sub)
            end
        end
        return
    end

    -- "split" snapshot: restore proportional fractions
    if #term_infos <= 1 then
        for _, info in ipairs(term_infos) do
            if snap.children then
                for _, sc in ipairs(snap.children) do
                    if sc.sub then
                        restore_node(info.child, term_map, sc.sub)
                        return
                    end
                end
            end
        end
        return
    end

    if snap.dir ~= dir or not snap.children then
        return
    end

    local snap_lookup = {}
    for _, sc in ipairs(snap.children) do
        snap_lookup[sc.keys_id] = sc
    end

    local all_matched = true
    for _, info in ipairs(term_infos) do
        if not snap_lookup[info.keys_id] then
            all_matched = false
            break
        end
    end

    if all_matched then
        local total = 0
        for _, info in ipairs(term_infos) do
            total = total + (dir == "row" and subtree_width(info.child) or subtree_height(info.child))
        end

        if total > 0 then
            for _, info in ipairs(term_infos) do
                local sc = snap_lookup[info.keys_id]
                local min_size = dir == "row" and 10 or 4
                local target = math.max(min_size, math.floor(total * sc.fraction + 0.5))
                local w = first_leaf_win(info.child)
                if w and vim.api.nvim_win_is_valid(w) then
                    if dir == "row" then
                        vim.wo[w].winfixwidth = false
                        vim.api.nvim_win_set_width(w, target)
                    else
                        vim.wo[w].winfixheight = false
                        vim.api.nvim_win_set_height(w, target)
                    end
                end
            end
        end
    end

    for _, info in ipairs(term_infos) do
        local sc = snap_lookup[info.keys_id]
        if sc and sc.sub then
            restore_node(info.child, term_map, sc.sub)
        end
    end
end

---Restore terminal layout from saved snapshot.
---Falls back to equalize_terminals() if snapshot doesn't match current state.
---@return nil
function M.restore_layout()
    local wins = win.all_terminal_windows()
    if #wins == 0 then
        return
    end

    if not state.saved_layout then
        if #wins >= 2 then
            M.equalize_terminals()
        end
        return
    end

    local term_map = win.build_term_map()
    if vim.tbl_isempty(term_map) then
        return
    end

    ---@type table<tt.terminal.Key, boolean>
    local current_keys = {}
    for _, key in pairs(term_map) do
        current_keys[key] = true
    end
    local snap_keys = all_snapshot_keys(state.saved_layout)

    if not vim.deep_equal(current_keys, snap_keys) then
        if #wins >= 2 then
            M.equalize_terminals()
        end
        return
    end

    for _, w in ipairs(wins) do
        if vim.api.nvim_win_is_valid(w) then
            vim.wo[w].winfixwidth = false
            vim.wo[w].winfixheight = false
        end
    end

    restore_node(vim.fn.winlayout(), term_map, state.saved_layout)
end

---Capture current layout proportions (called on WinResized/WinLeave).
---@return nil
function M.capture_layout()
    if state.restoring then
        return
    end
    local snap = M.snapshot_layout()
    if snap then
        state.saved_layout = snap
    end
end

return M

local M = {}

local utils = require "tt.utils"

-- ═══════════════════════════════════════════════════════════════════════════
-- Terminal Management System
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Creation (always opens a new terminal):
--   <leader>ht   New horizontal (bottom) terminal
--   <leader>vt   New vertical   (right)  terminal
--   <leader>ft   Toggle a full-screen float terminal
--   <leader>bt   Toggle a btop float terminal
--
-- Toggle:
--   <leader>tt   Toggle the last active split terminal (hide / show)
--   <leader>`    Toggle ALL split terminals at once
--
-- In-terminal:
--   <C-/>        Hide the current terminal
--   <C-h/j/k/l> Navigate to neighbouring window
--   <Esc>        Exit terminal mode
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Snacks terminal defaults ─────────────────────────────────────────────

---@type snacks.terminal.Config|{}
M.terminal = {
    win = {
        keys = {
            term_normal = {
                "<esc>",
                function()
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
            nav_h = {
                "<C-h>",
                function()
                    vim.cmd.wincmd "h"
                end,
                mode = { "n", "t" },
                desc = "Go to left window",
            },
            nav_j = {
                "<C-j>",
                function()
                    vim.cmd.wincmd "j"
                end,
                mode = { "n", "t" },
                desc = "Go to lower window",
            },
            nav_k = {
                "<C-k>",
                function()
                    vim.cmd.wincmd "k"
                end,
                mode = { "n", "t" },
                desc = "Go to upper window",
            },
            nav_l = {
                "<C-l>",
                function()
                    vim.cmd.wincmd "l"
                end,
                mode = { "n", "t" },
                desc = "Go to right window",
            },
        },
    },
}

-- ── Internal state ───────────────────────────────────────────────────────

local next_count = { horizontal = 0, vertical = 0 }

--- Global creation sequence for ordering restores.
local creation_seq = 0

--- Saved layout tree snapshot with proportional sizes for restore.
--- Captured on every resize so hide/show preserves manual resizing.
---@type table|nil
local saved_layout = nil

--- Guard: skip capture while we are restoring layout.
local restoring = false

--- Every split terminal ever created: "orientation:count" → config.
---@type table<string, { orientation: string, count: number, position: string, seq: number }>
local registry = {}

--- Terminal keys visible before the last global hide.
---@type string[]
local restore_snapshot = {}

--- Key of the last focused / created split terminal.
---@type string|nil
local last_terminal_key = nil

--- Forward declaration: defined below but referenced by toggle_terminal.
local visible_terminal_keys

-- ── Layout helpers ───────────────────────────────────────────────────────

--- Find the window handle for a specific terminal.
local function find_terminal_window(orientation, count)
    local marker = "snacks_terminal_" .. orientation
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if not vim.api.nvim_win_is_valid(win) then
            goto skip
        end
        local t = vim.b[vim.api.nvim_win_get_buf(win)].snacks_terminal
        if t and type(t) == "table" and type(t.env) == "table" and t.env[marker] and (t.id or 1) == count then
            return win
        end
        ::skip::
    end
    return nil
end

--- Find the Snacks terminal object by scanning all known terminals.
--- More reliable than Snacks.terminal.get() which can fail if cwd changed.
local function find_snacks_terminal_obj(orientation, count)
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

-- ── Sizing ───────────────────────────────────────────────────────────────

--- Collect ALL visible terminal windows (both orientations).
local function all_terminal_windows()
    local wins = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if not vim.api.nvim_win_is_valid(win) then
            goto skip
        end
        local t = vim.b[vim.api.nvim_win_get_buf(win)].snacks_terminal
        if
            t
            and type(t) == "table"
            and type(t.env) == "table"
            and (t.env.snacks_terminal_vertical or t.env.snacks_terminal_horizontal)
        then
            wins[#wins + 1] = win
        end
        ::skip::
    end
    return wins
end

-- ── Tree-based equalization ───────────────────────────────────────────
-- Vim's window layout is a tree.  Each split creates exactly two
-- children (binary tree).  The old flat approach tried to set every
-- terminal width independently, which cascaded unpredictably because
-- nvim_win_set_width redistributes space among TRUE tree-siblings.
--
-- New approach: walk the tree via vim.fn.winlayout(), and at each node
-- that has ≥2 children containing terminals, set only the FIRST child's
-- size.  In a binary tree that means exactly ONE set_width/set_height
-- call per tree level — the sibling auto-adjusts.  No cascade.
--
-- Unit counting:
--   Width distribution ("row" node):
--     • leaf terminal           → 1 column
--     • col (vertical stack)    → 1 column  (stacking doesn't add width)
--     • row (horizontal spread) → sum of children's column units
--   Height distribution ("col" node):
--     • leaf terminal           → 1 row
--     • row (horizontal spread) → 1 row     (spreading doesn't add height)
--     • col (vertical stack)    → sum of children's row units

--- Count terminal leaf windows inside a layout-tree node.
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

--- Count visual columns (for width distribution).
--- A leaf or a vertical stack ("col") counts as 1 column.
--- A horizontal row ("row") counts as the sum of its children's columns.
local function column_units(node, term_set)
    if node[1] == "leaf" then
        return term_set[node[2]] and 1 or 0
    end
    if count_term_leaves(node, term_set) == 0 then
        return 0
    end
    if node[1] == "col" then
        return 1 -- vertical stack = one column
    end
    -- "row" → sum of children
    local total = 0
    for _, child in ipairs(node[2]) do
        total = total + column_units(child, term_set)
    end
    return total
end

--- Count visual rows (for height distribution).
--- A leaf or a horizontal row ("row") counts as 1 row.
--- A vertical stack ("col") counts as the sum of its children's rows.
local function row_units(node, term_set)
    if node[1] == "leaf" then
        return term_set[node[2]] and 1 or 0
    end
    if count_term_leaves(node, term_set) == 0 then
        return 0
    end
    if node[1] == "row" then
        return 1 -- horizontal row = one row
    end
    -- "col" → sum of children
    local total = 0
    for _, child in ipairs(node[2]) do
        total = total + row_units(child, term_set)
    end
    return total
end

--- Return the first leaf window-id in a subtree.
local function first_leaf_win(node)
    if node[1] == "leaf" then
        return node[2]
    end
    return first_leaf_win(node[2][1])
end

--- Compute the total width of a layout subtree (leaves + separators).
local function subtree_width(node)
    if node[1] == "leaf" then
        if vim.api.nvim_win_is_valid(node[2]) then
            return vim.api.nvim_win_get_width(node[2])
        end
        return 0
    end
    if node[1] == "row" then
        local total = 0
        for i, child in ipairs(node[2]) do
            total = total + subtree_width(child)
            if i < #node[2] then
                total = total + 1
            end -- separator
        end
        return total
    end
    -- "col": stacked children share the same width
    local mx = 0
    for _, child in ipairs(node[2]) do
        mx = math.max(mx, subtree_width(child))
    end
    return mx
end

--- Compute the total height of a layout subtree (leaves + statuslines).
local function subtree_height(node)
    if node[1] == "leaf" then
        if vim.api.nvim_win_is_valid(node[2]) then
            return vim.api.nvim_win_get_height(node[2])
        end
        return 0
    end
    if node[1] == "col" then
        local total = 0
        for i, child in ipairs(node[2]) do
            total = total + subtree_height(child)
            if i < #node[2] then
                total = total + 1
            end -- statusline
        end
        return total
    end
    -- "row": side-by-side children share the same height
    local mx = 0
    for _, child in ipairs(node[2]) do
        mx = math.max(mx, subtree_height(child))
    end
    return mx
end

--- Walk the layout tree and equalize terminal windows.
--- At each "row" node: distribute width proportional to column_units.
--- At each "col" node: distribute height proportional to row_units.
--- For a binary tree this is exactly 1 resize call per level.
local function equalize_node(node, term_set)
    if node[1] == "leaf" then
        return
    end
    local dir = node[1] -- "row" (side-by-side) or "col" (stacked)
    local children = node[2]

    -- Gather children that contain at least one terminal leaf
    local infos = {}
    for _, child in ipairs(children) do
        local tc = count_term_leaves(child, term_set)
        if tc > 0 then
            infos[#infos + 1] = { node = child }
        end
    end

    if #infos >= 2 then
        if dir == "row" then
            -- Side-by-side: equalize widths by column units
            local total_w = 0
            local total_units = 0
            for _, info in ipairs(infos) do
                info.w = subtree_width(info.node)
                info.units = column_units(info.node, term_set)
                total_w = total_w + info.w
                total_units = total_units + info.units
            end
            if total_units > 0 then
                for i = 1, #infos - 1 do
                    local target = math.max(10, math.floor(total_w * infos[i].units / total_units))
                    local win = first_leaf_win(infos[i].node)
                    if win and vim.api.nvim_win_is_valid(win) then
                        vim.wo[win].winfixwidth = false
                        vim.api.nvim_win_set_width(win, target)
                    end
                end
            end
        else
            -- Stacked: equalize heights by row units
            local total_h = 0
            local total_units = 0
            for _, info in ipairs(infos) do
                info.h = subtree_height(info.node)
                info.units = row_units(info.node, term_set)
                total_h = total_h + info.h
                total_units = total_units + info.units
            end
            if total_units > 0 then
                for i = 1, #infos - 1 do
                    local target = math.max(4, math.floor(total_h * infos[i].units / total_units))
                    local win = first_leaf_win(infos[i].node)
                    if win and vim.api.nvim_win_is_valid(win) then
                        vim.wo[win].winfixheight = false
                        vim.api.nvim_win_set_height(win, target)
                    end
                end
            end
        end
    end

    -- Recurse into children (depth-first, bottom-up sizes settle naturally)
    for _, child in ipairs(children) do
        equalize_node(child, term_set)
    end
end

--- Equalize all terminal windows by walking the layout tree.
local function equalize_terminals()
    local wins = all_terminal_windows()
    if #wins < 2 then
        return
    end
    -- Build a set for O(1) lookup
    local term_set = {}
    for _, w in ipairs(wins) do
        term_set[w] = true
    end
    -- Clear winfixwidth/winfixheight on all terminals so resizes work
    for _, w in ipairs(wins) do
        if vim.api.nvim_win_is_valid(w) then
            vim.wo[w].winfixwidth = false
            vim.wo[w].winfixheight = false
        end
    end
    equalize_node(vim.fn.winlayout(), term_set)
end

-- ── Layout snapshot / restore ─────────────────────────────────────────
-- Captures the full proportional tree of terminal window sizes so that
-- hide/show preserves manual resizing — including complex layouts like
-- vertical splits nested inside horizontal splits.
--
-- The snapshot is a recursive tree mirroring vim.fn.winlayout(), pruned
-- to nodes that branch into multiple terminal-containing subtrees.
-- Each node stores the split direction and per-child fractional sizes.

--- Build a map from window-id → terminal key ("vertical:1", etc.)
local function build_term_map()
    local map = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if not vim.api.nvim_win_is_valid(win) then
            goto skip
        end
        local t = vim.b[vim.api.nvim_win_get_buf(win)].snacks_terminal
        if t and type(t) == "table" and type(t.env) == "table" then
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

--- Recursively collect sorted terminal keys from a layout subtree.
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

--- Capture proportional layout as a tree snapshot.
--- Two types of nodes:
---   "split" — multiple children contain terminals; saves per-child fractions
---   "edge"  — only one child has terminals; saves its absolute size (the
---             editor-to-terminal boundary) plus a sub-snapshot for nested splits
---@return table|nil snapshot
local function snapshot_node(node, term_map)
    if node[1] == "leaf" then
        return nil
    end

    local dir = node[1] -- "row" or "col"
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

    -- Single branch with terminals: save the edge size (editor↔terminal boundary)
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

    -- Multiple branches: save fractional sizes between terminal groups
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

--- Capture a full layout snapshot of all terminal windows.
local function snapshot_layout()
    local term_map = build_term_map()
    if vim.tbl_isempty(term_map) then
        return nil
    end
    return snapshot_node(vim.fn.winlayout(), term_map)
end

--- Collect all terminal keys mentioned anywhere in a snapshot.
local function all_snapshot_keys(snap)
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

    -- "split" type
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

--- Apply a saved snapshot to the current window tree.
local function restore_node(node, term_map, snap)
    if not snap or node[1] == "leaf" then
        return
    end

    local dir = node[1]
    local children = node[2]

    -- Find children that contain terminal windows
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

    -- ── Handle "edge" snapshot: restore the terminal area's absolute size ──
    if snap.type == "edge" then
        if #term_infos == 1 and dir == snap.dir then
            local info = term_infos[1]
            local win = first_leaf_win(info.child)
            if win and vim.api.nvim_win_is_valid(win) then
                if dir == "col" then
                    vim.wo[win].winfixheight = false
                    vim.api.nvim_win_set_height(win, snap.size)
                else
                    vim.wo[win].winfixwidth = false
                    vim.api.nvim_win_set_width(win, snap.size)
                end
            end
            -- Recurse into the sub-snapshot
            if snap.sub then
                restore_node(info.child, term_map, snap.sub)
            end
        else
            -- Structure changed, try to apply sub-snapshot anyway
            if snap.sub then
                for _, info in ipairs(term_infos) do
                    restore_node(info.child, term_map, snap.sub)
                end
            end
        end
        return
    end

    -- ── Handle "split" snapshot: restore proportional fractions ──────────
    -- Single branch: recurse, trying to match sub-snapshots
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

    -- Multiple branches: apply saved proportions if direction matches
    if snap.dir ~= dir or not snap.children then
        return
    end

    local snap_lookup = {}
    for _, sc in ipairs(snap.children) do
        snap_lookup[sc.keys_id] = sc
    end

    -- Verify all current children have a saved fraction
    local all_matched = true
    for _, info in ipairs(term_infos) do
        if not snap_lookup[info.keys_id] then
            all_matched = false
            break
        end
    end

    if all_matched then
        -- Compute total available space
        local total = 0
        for _, info in ipairs(term_infos) do
            if dir == "row" then
                total = total + subtree_width(info.child)
            else
                total = total + subtree_height(info.child)
            end
        end

        -- Apply fractions to ALL terminal children
        if total > 0 then
            for i = 1, #term_infos do
                local info = term_infos[i]
                local sc = snap_lookup[info.keys_id]
                local min_size = dir == "row" and 10 or 4
                local target = math.max(min_size, math.floor(total * sc.fraction + 0.5))
                local win = first_leaf_win(info.child)
                if win and vim.api.nvim_win_is_valid(win) then
                    if dir == "row" then
                        vim.wo[win].winfixwidth = false
                        vim.api.nvim_win_set_width(win, target)
                    else
                        vim.wo[win].winfixheight = false
                        vim.api.nvim_win_set_height(win, target)
                    end
                end
            end
        end
    end

    -- Recurse into children for nested proportions
    for _, info in ipairs(term_infos) do
        local sc = snap_lookup[info.keys_id]
        if sc and sc.sub then
            restore_node(info.child, term_map, sc.sub)
        end
    end
end

--- Restore the full terminal layout from the saved snapshot.
--- Falls back to equalize_terminals() if no snapshot or terminal set changed.
local function restore_layout()
    local wins = all_terminal_windows()
    if #wins < 2 then
        return
    end

    if not saved_layout then
        equalize_terminals()
        return
    end

    local term_map = build_term_map()
    if vim.tbl_isempty(term_map) then
        return
    end

    -- Verify the snapshot covers the same terminal set
    local current_keys = {}
    for _, key in pairs(term_map) do
        current_keys[key] = true
    end
    local snap_keys = all_snapshot_keys(saved_layout)

    if not vim.deep_equal(current_keys, snap_keys) then
        equalize_terminals()
        return
    end

    -- Clear fix flags so resizes work
    for _, w in ipairs(wins) do
        if vim.api.nvim_win_is_valid(w) then
            vim.wo[w].winfixwidth = false
            vim.wo[w].winfixheight = false
        end
    end

    restore_node(vim.fn.winlayout(), term_map, saved_layout)
end

--- After Snacks creates/shows a split it stores vim.w[].snacks_win with
--- the original position ("bottom", "right", …) and schedules an
--- equalize pass that groups ALL windows sharing (relative, position).
--- That groups unrelated terminals (e.g. ht1 at the full bottom and ht2
--- nested inside a vt column).  Giving each managed terminal a unique
--- position tag prevents the grouping while leaving Snacks' toggle and
--- close logic intact (they use the terminal id, not the win tag).
local function defuse_snacks_equalize()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if not vim.api.nvim_win_is_valid(win) then
            goto continue
        end
        local buf = vim.api.nvim_win_get_buf(win)
        local t = vim.b[buf].snacks_terminal
        if t and type(t) == "table" and type(t.env) == "table" then
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

-- ── Terminal creation ────────────────────────────────────────────────────

local function create_terminal(position)
    local vertical = position == "right"
    local orientation = vertical and "vertical" or "horizontal"
    local marker = "snacks_terminal_" .. orientation
    local dim = vertical and "width" or "height"

    next_count[orientation] = next_count[orientation] + 1
    local count = next_count[orientation]
    local key = orientation .. ":" .. count

    creation_seq = creation_seq + 1
    registry[key] = { orientation = orientation, count = count, position = position, seq = creation_seq }
    last_terminal_key = key

    -- Suppress redraws until the layout is final (including Snacks'
    -- scheduled callbacks that fire on the next event-loop tick).
    local lr = vim.o.lazyredraw
    vim.o.lazyredraw = true

    vim.o.equalalways = false

    for _, w in ipairs(all_terminal_windows()) do
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

    defuse_snacks_equalize()
    equalize_terminals()

    -- Hold lazyredraw through Snacks' vim.schedule callbacks, then
    -- re-equalize and paint one clean frame.
    equalize_terminals()
    vim.o.lazyredraw = lr
    vim.cmd "redraw"
end

local function toggle_terminal(key)
    local cfg = registry[key]
    if not cfg then
        return
    end
    local marker = "snacks_terminal_" .. cfg.orientation
    local was_visible = find_terminal_window(cfg.orientation, cfg.count) ~= nil

    local lr = vim.o.lazyredraw
    vim.o.lazyredraw = true

    local ea = vim.o.equalalways
    vim.o.equalalways = false

    if was_visible then
        -- Freeze snapshot during hide so WinResized doesn't overwrite it
        restoring = true
        Snacks.terminal.toggle(nil, {
            count = cfg.count,
            env = { [marker] = "1" },
        })
        restoring = false
    else
        local t = find_snacks_terminal_obj(cfg.orientation, cfg.count)
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

    defuse_snacks_equalize()

    if was_visible then
        if #visible_terminal_keys() == 0 then
            vim.o.equalalways = ea
        end
        vim.o.lazyredraw = lr
        vim.cmd.stopinsert()
    else
        restore_layout()
        restore_layout()
        vim.o.lazyredraw = lr
        vim.cmd "redraw"
        -- Re-apply after Snacks' deferred callbacks
        local snap = saved_layout
        vim.schedule(function()
            restoring = true
            saved_layout = snap
            restore_layout()
            restoring = false
        end)
    end
end

-- ── Visibility scanning ─────────────────────────────────────────────────

function visible_terminal_keys()
    local keys, seen = {}, {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if not vim.api.nvim_win_is_valid(win) then
            goto skip
        end
        local t = vim.b[vim.api.nvim_win_get_buf(win)].snacks_terminal
        if t and type(t) == "table" and type(t.env) == "table" then
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
                    if not registry[key] then
                        creation_seq = creation_seq + 1
                        registry[key] = {
                            orientation = orientation,
                            count = t.id or 1,
                            position = orientation == "vertical" and "right" or "bottom",
                            seq = creation_seq,
                        }
                    end
                end
            end
        end
        ::skip::
    end
    return keys
end

-- ── Global toggle ────────────────────────────────────────────────────────

local function toggle_all_terminals()
    local vis = visible_terminal_keys()

    local lr = vim.o.lazyredraw
    vim.o.lazyredraw = true

    if #vis > 0 then
        -- Hide all — freeze the snapshot so WinResized events during
        -- the sequential hides don't progressively erase terminals.
        restore_snapshot = vis
        restoring = true
        local ea = vim.o.equalalways
        vim.o.equalalways = false
        for _, key in ipairs(vis) do
            local cfg = registry[key]
            if cfg then
                local marker = "snacks_terminal_" .. cfg.orientation
                Snacks.terminal.toggle(nil, {
                    count = cfg.count,
                    env = { [marker] = "1" },
                })
            end
        end
        vim.o.equalalways = ea
        restoring = false
        vim.o.lazyredraw = lr
        vim.cmd.stopinsert()
        return
    end

    -- Show all — restore terminals synchronously so Neovim redraws only
    -- once at the end (no intermediate flicker from deferred shows).

    -- Sort by creation order so the window tree is rebuilt correctly.
    -- Snacks reuses original opts (relative="win"), so cursor position
    -- after each show determines where the next split lands.
    local ordered = vim.deepcopy(restore_snapshot)
    table.sort(ordered, function(a, b)
        local sa = registry[a] and registry[a].seq or 0
        local sb = registry[b] and registry[b].seq or 0
        return sa < sb
    end)

    vim.o.equalalways = false
    restoring = true

    -- Focus a non-terminal window (editor) so the first terminal
    -- splits the editor, not some other terminal.
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_is_valid(win) then
            local buf = vim.api.nvim_win_get_buf(win)
            if not vim.b[buf].snacks_terminal then
                vim.api.nvim_set_current_win(win)
                break
            end
        end
    end

    -- Show every terminal synchronously (no vim.defer_fn gaps).
    -- Window operations in Neovim are synchronous — the layout is
    -- updated before each call returns, so no "settle" delay is needed.
    for _, key in ipairs(ordered) do
        local cfg = registry[key]
        if cfg then
            -- Clear winfixwidth/winfixheight on existing terminal windows
            -- so the new split takes space from the parent, not a sibling.
            for _, w in ipairs(all_terminal_windows()) do
                if vim.api.nvim_win_is_valid(w) then
                    vim.wo[w].winfixwidth = false
                    vim.wo[w].winfixheight = false
                end
            end

            local marker = "snacks_terminal_" .. cfg.orientation
            local cur_win = vim.api.nvim_get_current_win()
            local t = find_snacks_terminal_obj(cfg.orientation, cfg.count)
            if t then
                t.opts.win = cur_win
                t:toggle()
            else
                Snacks.terminal.toggle(nil, {
                    count = cfg.count,
                    env = { [marker] = "1" },
                })
            end
            defuse_snacks_equalize()
        end
    end

    -- Restore saved proportions (falls back to equalize if snapshot
    -- doesn't match, e.g. after creating/closing terminals).
    restore_layout()

    -- Hold lazyredraw through Snacks' vim.schedule callbacks, then
    -- re-apply and paint one clean frame.
    restore_layout()
    restoring = false
    vim.o.lazyredraw = lr
    vim.cmd "redraw"

    -- Re-apply after Snacks' deferred callbacks settle (they run on
    -- vim.schedule and can override our sizes).
    local snap = saved_layout
    vim.schedule(function()
        restoring = true
        saved_layout = snap
        restore_layout()
        restoring = false
    end)
end

-- ── Layout persistence ────────────────────────────────────────────────────

local function capture_layout()
    if restoring then
        return
    end
    local snap = snapshot_layout()
    if snap then
        saved_layout = snap
    end
end

local function setup_layout_persistence()
    local group = vim.api.nvim_create_augroup("tt_snacks_terminal_size", { clear = true })
    vim.api.nvim_create_autocmd({ "WinResized", "WinLeave" }, {
        group = group,
        desc = "Persist snacks terminal layout proportions",
        callback = capture_layout,
    })
end

-- ── Last-terminal tracking ───────────────────────────────────────────────

local function setup_terminal_tracking()
    local group = vim.api.nvim_create_augroup("tt_terminal_tracking", { clear = true })
    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
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
                    last_terminal_key = orientation .. ":" .. (t.id or 1)
                end
            end
        end,
    })
end

-- ── Public helpers ────────────────────────────────────────────────────────

--- Hide all visible terminals (stashes them for <leader>` restore).
function M.hide_all()
    local vis = visible_terminal_keys()
    if #vis == 0 then
        return
    end
    restore_snapshot = vis
    restoring = true
    vim.o.equalalways = false
    for _, key in ipairs(vis) do
        local cfg = registry[key]
        if cfg then
            local marker = "snacks_terminal_" .. cfg.orientation
            Snacks.terminal.toggle(nil, {
                count = cfg.count,
                env = { [marker] = "1" },
            })
        end
    end
    restoring = false
end

-- ── Setup ────────────────────────────────────────────────────────────────

function M.setup()
    setup_layout_persistence()
    setup_terminal_tracking()

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
        if last_terminal_key then
            toggle_terminal(last_terminal_key)
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

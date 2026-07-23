---@alias tt.terminal.Orientation "vertical"|"horizontal"
---@alias tt.terminal.Position "right"|"bottom"
---@alias tt.terminal.Key string # "orientation:count", e.g. "vertical:1"

---@class tt.terminal.RegistryEntry
---@field orientation tt.terminal.Orientation Split direction of this terminal
---@field count integer 1-based per-orientation index (Snacks `count`)
---@field position tt.terminal.Position Screen edge the split was created against
---@field seq integer Monotonic creation order (used for restore ordering)

---Layout snapshot leaf: a single terminal branch pinned to a parent edge.
---@class tt.terminal.SnapshotEdge
---@field type "edge"
---@field dir "row"|"col" Winlayout direction of the parent split
---@field keys_id string Comma-joined sorted terminal keys under this branch
---@field size integer Captured pixel-cell size of the branch on that edge
---@field sub tt.terminal.LayoutSnapshot|nil Nested snapshot for descendants

---Layout snapshot node: multiple sibling branches with fractional sizes.
---@class tt.terminal.SnapshotSplit
---@field type "split"
---@field dir "row"|"col" Winlayout direction of the split
---@field children tt.terminal.SnapshotChild[] Ordered sibling branches

---@class tt.terminal.SnapshotChild
---@field keys_id string Comma-joined sorted terminal keys under this child
---@field fraction number Proportional size in [0,1] within its parent split
---@field sub tt.terminal.LayoutSnapshot|nil Nested snapshot for descendants

---@alias tt.terminal.LayoutSnapshot tt.terminal.SnapshotEdge|tt.terminal.SnapshotSplit

---@class tt.terminal.State
---@field next_count table<tt.terminal.Orientation, integer> Per-orientation terminal counters
---@field creation_seq integer Global creation sequence for ordering restores
---@field saved_layout tt.terminal.LayoutSnapshot|nil Proportional layout tree snapshot
---@field restoring boolean Guard flag: skip capture while restoring layout
---@field registry table<tt.terminal.Key, tt.terminal.RegistryEntry> All split terminals ever created
---@field restore_snapshot tt.terminal.Key[] Terminal keys visible before last global hide
---@field last_terminal_key tt.terminal.Key|nil Key of the last focused/created split terminal
local M = {
    next_count = { horizontal = 0, vertical = 0 },
    creation_seq = 0,
    saved_layout = nil,
    restoring = false,
    registry = {},
    restore_snapshot = {},
    last_terminal_key = nil,
}

return M

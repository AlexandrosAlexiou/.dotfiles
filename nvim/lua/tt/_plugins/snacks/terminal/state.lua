---@class tt.terminal.State
---@field next_count table<string, integer> Per-orientation terminal counters
---@field creation_seq integer Global creation sequence for ordering restores
---@field saved_layout table|nil Proportional layout tree snapshot
---@field restoring boolean Guard flag: skip capture while restoring layout
---@field registry table<string, tt.terminal.RegistryEntry> All split terminals ever created
---@field restore_snapshot string[] Terminal keys visible before last global hide
---@field last_terminal_key string|nil Key of the last focused/created split terminal
local M = {
    next_count = { horizontal = 0, vertical = 0 },
    creation_seq = 0,
    saved_layout = nil,
    restoring = false,
    registry = {},
    restore_snapshot = {},
    last_terminal_key = nil,
}

---@class tt.terminal.RegistryEntry
---@field orientation string
---@field count integer
---@field position string
---@field seq integer

return M

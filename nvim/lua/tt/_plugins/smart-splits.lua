local M = {}

function M.setup()
    local smart_splits = require "smart-splits"

    smart_splits.setup {
        -- The amount of lines/columns to resize by at a time
        default_amount = 3,

        -- Cursor follows when swapping buffers
        cursor_follows_swapped_bufs = true,

        -- Cursor will move on the same row when moving between buffers regardless of line numbers
        move_cursor_same_row = true,
    }

    -- Floats embedded in a split (e.g. the snacks explorer input/list, which are relative to the
    -- sidebar split) resize their parent split. Otherwise smart-splits jumps to the previous
    -- window and resizes that one instead.
    ---@param resize fun()
    local function resize_parent(resize)
        return function()
            local config = vim.api.nvim_win_get_config(0)
            if config.relative == "win" and config.win and vim.api.nvim_win_is_valid(config.win) then
                vim.api.nvim_win_call(config.win, resize)
            else
                resize()
            end
        end
    end

    local utils = require "tt.utils"
    utils.map("n", "<M-h>", resize_parent(smart_splits.resize_left), { desc = "Resize window left" })
    utils.map("n", "<M-j>", resize_parent(smart_splits.resize_down), { desc = "Resize window down" })
    utils.map("n", "<M-k>", resize_parent(smart_splits.resize_up), { desc = "Resize window up" })
    utils.map("n", "<M-l>", resize_parent(smart_splits.resize_right), { desc = "Resize window right" })
    utils.map("n", "<C-w>h", smart_splits.move_cursor_left, { desc = "Move cursor left" })
    utils.map("n", "<C-w>j", smart_splits.move_cursor_down, { desc = "Move cursor down" })
    utils.map("n", "<C-w>k", smart_splits.move_cursor_up, { desc = "Move cursor up" })
    utils.map("n", "<C-w>l", smart_splits.move_cursor_right, { desc = "Move cursor right" })
end

return M

local M = {}

local function setup_autocommands()
    vim.api.nvim_create_autocmd("BufRead", {
        group = vim.api.nvim_create_augroup("tt.TroubleQuickFix", { clear = true }),
        pattern = "*",
        callback = function(event)
            if vim.bo[event.buf].buftype == "quickfix" then
                vim.schedule(function()
                    vim.cmd.cclose()
                    vim.cmd.Trouble { "qflist", "open" }
                end)
            end
        end,
        desc = "Automatically open Trouble when quickfix list is opened.",
    })

    -- Trouble's float preview uses minimal window options and Neovim remembers window options
    -- per buffer, so jumping to a previewed file can inherit them in the main window.
    local minimal_opts = {
        "cursorcolumn",
        "cursorline",
        "cursorlineopt",
        "fillchars",
        "list",
        "number",
        "relativenumber",
        "signcolumn",
        "spell",
        "statuscolumn",
        "winfixheight",
        "winfixwidth",
        "winhighlight",
        "wrap",
    }
    vim.api.nvim_create_autocmd("BufWinEnter", {
        group = vim.api.nvim_create_augroup("tt.TroubleWinOpts", { clear = true }),
        callback = function(event)
            local win = vim.api.nvim_get_current_win()
            if
                vim.bo[event.buf].buftype ~= ""
                or vim.api.nvim_win_get_config(win).relative ~= ""
                or not vim.wo[win].winhighlight:find "Trouble"
            then
                return
            end
            for _, name in ipairs(minimal_opts) do
                vim.wo[win][name] = vim.api.nvim_get_option_value(name, { scope = "global" })
            end
        end,
        desc = "Restore window options leaked from Trouble's preview window.",
    })
end

-- Neovim 0.12 parses treesitter trees in the decoration provider's `on_start`, which Trouble
-- doesn't hook, so only the initially visible results got highlighted. Parse the visible range
-- in `on_win` instead.
local function setup_treesitter_highlight()
    local TroubleTS = require "trouble.view.treesitter"
    local TSHighlighter = vim.treesitter.highlighter
    TroubleTS.setup()

    local function wrap(name)
        return function(_, win, buf, ...)
            if not TroubleTS.cache[buf] then
                return false
            end
            for _, hl in pairs(TroubleTS.cache[buf]) do
                if hl.enabled then
                    if name == "_on_win" then
                        local topline, botline = ...
                        hl.parser:parse { topline, botline + 1 }
                    end
                    TSHighlighter.active[buf] = hl.highlighter
                    TSHighlighter[name](_, win, buf, ...)
                end
            end
            TSHighlighter.active[buf] = nil
        end
    end

    vim.api.nvim_set_decoration_provider(vim.api.nvim_create_namespace "trouble.treesitter", {
        on_win = wrap "_on_win",
        on_range = wrap "_on_range",
    })
end

function M.setup()
    require("trouble").setup {
        auto_close = false, -- Auto close when there are no items
        auto_preview = true, -- Automatically open preview when on an item
        auto_refresh = true, -- Auto refresh when open
        auto_jump = false, -- Auto jump to the item when there's only one
        focus = true, -- Focus the window when opened
        restore = true, -- Restores the last location in the list when opening
        follow = true, -- Follow the current item
        indent_guides = true, -- Show indent guides
        warn_no_results = true, -- Show a warning when there are no results
        open_no_results = true, -- Open the trouble window when there are no results
        keys = {
            q = "close",
            go = "jump_close",
            o = "jump",
            ["<C-x>"] = "jump_split",
            ["<C-v>"] = "jump_vsplit",
            ["<Space>"] = "fold_toggle",
            ["<CR>"] = "jump_close",
        },
        win = {
            type = "split",
            position = "bottom",
            size = {
                height = 18,
            },
        },
        modes = {
            diagnostics_inline_preview = {
                mode = "diagnostics",
                preview = {
                    type = "split",
                    relative = "win",
                    position = "right",
                    size = 0.4,
                },
            },
            diagnostics_inline_preview_buffer = {
                mode = "diagnostics",
                preview = {
                    type = "split",
                    relative = "win",
                    position = "right",
                    size = 0.4,
                },
                filter = {
                    buf = 0,
                },
            },
            lsp_references = {
                preview = {
                    type = "float",
                    relative = "win",
                    border = "none",
                    size = {
                        height = 1,
                        width = 0.5,
                    },
                    position = { 0, 1 },
                },
            },
        },
    }

    setup_autocommands()
    setup_treesitter_highlight()

    -- stylua: ignore start
    local utils = require "tt.utils"
    utils.map("n", "<leader>td", "<Cmd>Trouble diagnostics_inline_preview toggle<CR>", { desc = "Trouble diagnostics" })
    utils.map("n", "<leader>tD", "<Cmd>Trouble diagnostics_inline_preview_buffer toggle<CR>", { desc = "Trouble diagnostics for current buffer" })
    utils.map("n", "<leader>tl", "<Cmd>Trouble loclist toggle<CR>", { desc = "Trouble loclist" })
    utils.map("n", "<leader>tq", "<Cmd>Trouble quickfix toggle<CR>", { desc = "Trouble quickfix" })
    utils.map("n", "<leader>tr", "<Cmd>Trouble lsp_references toggle<CR>", { desc = "Trouble lsp references" })
    utils.map("n", "<leader>ti", "<Cmd>Trouble lsp_implementations toggle<CR>", { desc = "Trouble lsp implementations" })
    utils.map("n", "<leader>ts", "<Cmd>Trouble lsp_document_symbols toggle<CR>", { desc = "Trouble lsp document symbols" })
    utils.map("n", "gr", "<Cmd>Trouble lsp_references toggle<CR>", { desc = "Trouble lsp references" })
    utils.map("n", "gi", "<Cmd>Trouble lsp_implementations toggle<CR>", { desc = "Trouble lsp implementations" })
    utils.map("n", "<C-LeftMouse>", "<Cmd>Trouble lsp_references toggle<CR>", { desc = "Trouble lsp references" })
    -- stylua: ignore end
end

return M

local M = {}

function M.setup()
    require("toggleterm").setup {
        open_mapping = [[<C-\>]],
        size = function(term)
            if term.direction == "horizontal" then
                return math.floor(vim.o.lines * 0.3)
            elseif term.direction == "vertical" then
                return math.floor(vim.o.columns * 0.4)
            end
        end,
        shade_terminals = true,
        start_in_insert = true,
        insert_mappings = true,
        terminal_mappings = true,
        persist_size = true,
        persist_mode = true,
        close_on_exit = true,
        auto_scroll = true,
        direction = "horizontal",
        float_opts = {
            border = "rounded",
            winblend = 0,
        },
    }

    -- Terminal-mode keymaps for any terminal buffer (toggleterm or plain :terminal).
    vim.api.nvim_create_autocmd("TermOpen", {
        group = vim.api.nvim_create_augroup("tt.ToggleTerm", { clear = true }),
        callback = function(args)
            local opts = { buffer = args.buf, silent = true }
            vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)
            vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
            vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
            vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
            vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
            vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
        end,
        desc = "Set terminal-mode keymaps for terminal buffers",
    })

    -- Spawn a terminal in a vim split of the current window so multiple
    -- terminals can coexist side-by-side (tmux-style panes). Splits use the
    -- built-in :terminal — toggleterm's `direction` only supports edge
    -- placements (horizontal/vertical/tab/float), not arbitrary window splits.
    local function split_term(direction)
        if direction == "horizontal" then
            vim.cmd "belowright new | terminal"
            vim.cmd.startinsert()
        elseif direction == "vertical" then
            vim.cmd "rightbelow vnew | terminal"
            vim.cmd.startinsert()
        elseif direction == "tab" then
            vim.cmd "tabnew | terminal"
            vim.cmd.startinsert()
        elseif direction == "float" then
            require("toggleterm.terminal").Terminal:new({ direction = "float" }):open()
        end
    end

    local utils = require "tt.utils"

    -- stylua: ignore start
    utils.map({ "n", "t" }, "<leader>th", function() split_term("horizontal") end, { desc = "Split horizontal terminal" })
    utils.map({ "n", "t" }, "<leader>tv", function() split_term("vertical") end,   { desc = "Split vertical terminal" })
    utils.map({ "n", "t" }, "<leader>tf", function() split_term("float") end,      { desc = "New floating terminal" })
    utils.map({ "n", "t" }, "<leader>tx", function() split_term("tab") end,        { desc = "Open terminal in new tab" })
    utils.map({ "n", "t" }, "<leader>tA", "<Cmd>ToggleTermToggleAll<CR>",          { desc = "Toggle all terminals" })
    -- stylua: ignore end
end

return M

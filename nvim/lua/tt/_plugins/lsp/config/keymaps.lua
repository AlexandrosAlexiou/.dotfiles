local M = {}

local utils = require "tt.utils"

local function hover_on_new_window()
    vim.lsp.buf_request(
        0,
        "textDocument/hover",
        vim.lsp.util.make_position_params(0, "utf-8"),
        function(_, result, ctx, config)
            config = config or {}
            config.focus_id = ctx.method

            -- Ignore result since buffer changed. This happens for slow language servers
            if vim.api.nvim_get_current_buf() ~= ctx.bufnr then
                return
            end

            -- No information available
            if not (result and result.contents) then
                return
            end

            local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)

            -- Open an new window with the hover information
            vim.cmd.new()
            vim.api.nvim_set_option_value("filetype", "markdown", { scope = "local" })
            vim.api.nvim_set_option_value("buftype", "nofile", { scope = "local" })
            vim.api.nvim_set_option_value("buflisted", false, { scope = "local" })
            vim.api.nvim_buf_set_lines(0, 0, -1, false, markdown_lines)

            utils.map("n", "q", "<C-w>c", { buffer = true })
        end
    )
end

local function goto_definition_split(split_type)
    -- Resolve the definition first, then open the target buffer directly in a
    -- new split — the original buffer never appears in it (no flicker).
    vim.lsp.buf.definition {
        on_list = function(options)
            local item = options.items and options.items[1]
            if not item then
                vim.notify("No definition found", vim.log.levels.INFO)
                return
            end

            if vim.fn.isdirectory(item.filename) == 1 then
                vim.cmd(split_type == "v" and "rightbelow vsplit" or "rightbelow split")
                vim.w.goto_split = true
                require("oil").open(item.filename)
                return
            end

            -- bufadd + nvim_open_win loads the buffer straight into the new
            -- window (BufReadCmd handles jar://jrt:// decompiled sources)
            local buf = vim.fn.bufadd(item.filename)
            vim.bo[buf].buflisted = true
            local win = vim.api.nvim_open_win(buf, true, {
                split = split_type == "v" and "right" or "below",
                win = 0,
            })
            vim.w[win].goto_split = true
            pcall(vim.api.nvim_win_set_cursor, win, { item.lnum, item.col - 1 })
        end,
    }
end

function M.on_attach(_, bufnr)
    local function opts(desc)
        return { desc = desc, buffer = bufnr }
    end

    utils.map("n", "K", vim.lsp.buf.hover, opts "Display hover information about symbol")
    utils.map("n", "<leader>K", hover_on_new_window, opts "Display hover information about symbol on new window")
    utils.map("n", "gv", function()
        goto_definition_split "v"
    end, opts "Go to the definition of the symbol in a vertical split")
    utils.map("n", "gh", function()
        goto_definition_split "h"
    end, opts "Go to the definition of the symbol in a horizontal split")
    utils.map("n", "dl", "<Cmd>lua vim.diagnostic.setloclist()<CR>", opts "Add buffer diagnostics to the loclist")
    utils.map("n", "dq", "<Cmd>lua vim.diagnostic.setqflist()<CR>", opts "Add buffer diagnostics to the qflist")
    utils.map("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition" })

    local ft = vim.bo.filetype
    if ft == "c" or ft == "cpp" or ft == "h" or ft == "hpp" then
        utils.map("n", "<leader>ko", "<Cmd>LspClangdSwitchSourceHeader<CR>", opts "Switch C++ source/header ")
        utils.map("n", "<M-o>", "<Cmd>LspClangdSwitchSourceHeader<CR>", opts "Switch C++ source/header ")
    end
end

return M

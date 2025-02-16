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
    local definition_done = false -- Add a flag to prevent multiple splits

    vim.lsp.buf_request(0, "textDocument/definition", vim.lsp.util.make_position_params(), function(_, result, ctx)
        -- Prevent multiple splits if one result has already been processed
        if definition_done then
            return
        end

        -- Ensure we have a valid result
        if result and result[1] then
            definition_done = true -- Set the flag to true after handling the first result

            -- Perform the split based on the provided type (vertical or horizontal)
            vim.cmd(split_type == "v" and "vsplit" or "split")

            -- Get the client by ID and jump to the location with the appropriate encoding
            local client = vim.lsp.get_client_by_id(ctx.client_id)
            vim.lsp.util.show_document(result[1], client and client.offset_encoding or "utf-8")
        end
    end)
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

    local ft = vim.bo.filetype
    if ft == "c" or ft == "cpp" or ft == "h" or ft == "hpp" then
        utils.map("n", "<leader>ko", "<Cmd>LspClangdSwitchSourceHeader<CR>", opts "Switch C++ source/header ")
        utils.map("n", "<M-o>", "<Cmd>LspClangdSwitchSourceHeader<CR>", opts "Switch C++ source/header ")
    end
end

return M

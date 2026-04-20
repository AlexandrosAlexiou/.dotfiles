local M = {}

function M.setup()
    -- Check if LSP is disabled
    if vim.g.disable_lsp then
        return
    end

    require("tt._plugins.lsp.config.diagnostics").setup()
    require("tt._plugins.lsp.config.attach").setup()
    require("tt._plugins.lsp.config.servers").setup()
end

local utils = require "tt.utils"

utils.map("n", "<leader>li", function()
    vim.cmd.checkhealth { "vim.lsp" }
end)

utils.map("n", "<leader>lr", function()
    vim.cmd.lsp { "restart" }
end)

return M

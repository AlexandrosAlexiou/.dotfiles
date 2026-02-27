local M = {}

function M.setup()
    vim.g.rustaceanvim = {
        tools = {
            hover_actions = {
                replace_builtin_hover = false,
            },
        },
        server = {
            on_attach = function(_, bufnr)
                local utils = require "tt.utils"
                utils.map("n", "<leader>ra", function()
                    vim.cmd.RustLsp "codeAction"
                end, { desc = "Rust code action", buffer = bufnr })
                utils.map("n", "<leader>rd", function()
                    vim.cmd.RustLsp "debuggables"
                end, { desc = "Rust debuggables", buffer = bufnr })
                utils.map("n", "<leader>rr", function()
                    vim.cmd.RustLsp "runnables"
                end, { desc = "Rust runnables", buffer = bufnr })
                utils.map("n", "<leader>rt", function()
                    vim.cmd.RustLsp "testables"
                end, { desc = "Rust testables", buffer = bufnr })
                utils.map("n", "<leader>re", function()
                    vim.cmd.RustLsp "explainError"
                end, { desc = "Rust explain error", buffer = bufnr })
                utils.map("n", "<leader>rc", function()
                    vim.cmd.RustLsp "openCargo"
                end, { desc = "Rust open Cargo.toml", buffer = bufnr })
                utils.map("n", "<leader>rp", function()
                    vim.cmd.RustLsp "parentModule"
                end, { desc = "Rust parent module", buffer = bufnr })
                utils.map("n", "<leader>rm", function()
                    vim.cmd.RustLsp "expandMacro"
                end, { desc = "Rust expand macro", buffer = bufnr })
            end,
            default_settings = {
                ["rust-analyzer"] = {
                    cargo = {
                        allFeatures = true,
                    },
                    checkOnSave = true,
                    check = {
                        command = "clippy",
                    },
                    inlayHints = {
                        chainingHints = { enable = true },
                        closingBraceHints = { enable = true },
                        parameterHints = { enable = true },
                        typeHints = { enable = true },
                    },
                    procMacro = {
                        enable = true,
                    },
                },
            },
        },
    }
end

return M

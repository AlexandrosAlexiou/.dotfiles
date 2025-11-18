local format_utils = require "tt._plugins.format.utils"

local M = {}

--- Formats the current buffer, with optional customization through specified opts.
---@param opts? table
function M.format(opts)
    local default_opts = {
        async = false,
        lsp_fallback = true,
        timeout_ms = 2500,
    }
    local format_opts = vim.tbl_extend("force", default_opts, opts or {})
    require("conform").format(format_opts)
end

--- Returns a list of the formatters that are registered in conform.
---@return table: List with the formatter names.
function M.get_formatters()
    local registered_formatters = require("conform").list_all_formatters()
    local formatters = {}
    for _, formatter_info in ipairs(registered_formatters) do
        table.insert(formatters, formatter_info.name)
    end
    return formatters
end

--- Adds a pre format handler to be invoked before formatting for the given bufnr.
---@param bufnr Buffer
---@param handler fun()
function M.add_pre_format_handler(bufnr, handler)
    format_utils.add_pre_format_handler(bufnr, handler)
end

--- Removes a handler from the pre format handlers table for the given bufnr.
---@param bufnr Buffer
---@param handler? fun()
function M.remove_pre_format_handler(bufnr, handler)
    format_utils.remove_pre_format_handler(bufnr, handler)
end

function M.init()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
end

function M.setup()
    format_utils.setup()

    require("conform").setup {
        formatters_by_ft = {
            c = { "clang-format" },
            cpp = { "clang-format" },
            graphql = { "prettierd" },
            java = { "google-java-format" },
            kotlin = { "ktfmt" },
            lua = { "stylua" },
            python = { "autopep8" },
            sh = { "shfmt" },
            javascript = { "prettierd" },
            javascriptreact = { "prettierd" },
            typescript = { "prettierd" },
            typescriptreact = { "prettierd" },
            vue = { "prettierd" },
        },
        formatters = {
            ["clang-format"] = {
                prepend_args = { "-style=file" },
            },
            ktfmt = {
                prepend_args = { "--kotlinlang-style" },
            },
            shfmt = {
                prepend_args = { "-i", "4", "-bn", "-ci", "-sr" },
            },
        },
        format_on_save = function(bufnr)
            if vim.b.disable_autoformat or vim.g.disable_autoformat then
                return
            end
            local filetype = vim.bo[bufnr].filetype
            if format_utils.should_format(filetype, bufnr) then
                format_utils.run_pre_format_handlers(bufnr)
                M.format()
            end
        end,
    }

    local utils = require "tt.utils"

    utils.map("n", "<leader>ci", "<Cmd>ConformInfo<CR>", { desc = "Show conform information" })

    utils.map({ "n", "v" }, "<leader>fr", function()
        M.format { async = true }
    end, { desc = "Format the current buffer" })

    utils.map({ "n", "v" }, "<leader>fR", function()
        require("conform").format { formatters = { "injected" }, timeout_ms = 2500 }
    end, { desc = "Format injected code blocks for the current buffer" })
end

return M

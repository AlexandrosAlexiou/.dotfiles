local M = {}

function M.setup()
    local icons = require "tt.icons"

    -- Sign definitions for breakpoints / stopped frame.
    local signs = {
        DapBreakpoint = { text = icons.dap.Breakpoint, texthl = "DiagnosticError" },
        DapBreakpointCondition = { text = icons.dap.BreakpointCondition, texthl = "DiagnosticWarn" },
        DapBreakpointRejected = { text = icons.dap.BreakpointRejected[1], texthl = icons.dap.BreakpointRejected[2] },
        DapLogPoint = { text = icons.dap.LogPoint, texthl = "DiagnosticInfo" },
        DapStopped = { text = icons.dap.Stopped[1], texthl = icons.dap.Stopped[2], linehl = icons.dap.Stopped[3] },
    }

    for name, opts in pairs(signs) do
        vim.fn.sign_define(name, opts)
    end
end

return M

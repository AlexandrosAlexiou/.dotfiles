local M = {}

function M.setup()
    local neotest = require "neotest"

    neotest.setup {
        icons = {
            unknown = "󰙨",
            watching = "",
            running_animated = {
                "⠋",
                "⠙",
                "⠹",
                "⠸",
                "⠼",
                "⠴",
                "⠦",
                "⠧",
                "⠇",
                "⠏",
            },
        },
        adapters = {
            require "neotest-python",
            require "neotest-vitest" {
                dap = { justMyCode = false },
            },
            require("neotest-playwright").adapter {
                options = {
                    persist_project_selection = true,
                    enable_dynamic_test_discovery = false,
                },
            },
            require "neotest-plenary",
            require "neotest-vim-test" {
                ignore_file_types = { "lua" },
            },
        },
        status = { virtual_text = true },
        output = { open_on_run = true },
        quickfix = {
            open = function()
                require("trouble").open { mode = "quickfix", focus = false }
            end,
        },
    }

    local utils = require "tt.utils"

    utils.map("n", "<leader>sO", function()
        neotest.output.open { enter = true, auto_close = true }
    end, { desc = "Show Output" })

    utils.map("n", "<leader>rF", function()
        neotest.run.run(vim.fn.expand "%")
    end, { desc = "Run File" })

    utils.map("n", "<leader>rA", function()
        neotest.run.run(vim.loop.cwd())
    end, { desc = "Run All TestFiles" })

    utils.map("n", "<leader>rN", neotest.run.run, { desc = "Run Nearest" })

    utils.map("n", "<leader>rW", function()
        neotest.watch.toggle(vim.loop.cwd())
    end, { desc = "Watch file" })

    utils.map("n", "<leader>rL", neotest.run.run_last, { desc = "Run Last" })

    utils.map("n", "<leader>tc", neotest.summary.toggle, { desc = "Toggle Summary" })

    utils.map("n", "<leader>tC", neotest.run.stop, { desc = "Stop" })
end

return M

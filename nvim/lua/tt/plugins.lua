---@param config {args?:string[]|fun():string[]?}
local function get_args(config)
    local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
    config = vim.deepcopy(config)
    ---@cast args string[]
    config.args = function()
        local new_args = vim.fn.input("Run with args: ", table.concat(args, " ")) --[[@as string]]
        return vim.split(vim.fn.expand(new_args) --[[@as string]], " ")
    end
    return config
end

return {
    -- Colorschemes
    {
        {
            "EdenEast/nightfox.nvim",
            config = function()
                require("tt._plugins.nightfox").setup()
            end,
        },
        {
            "rose-pine/neovim",
            lazy = true,
            name = "rose-pine",
            config = function()
                require("tt._plugins.rose-pine").setup()
            end,
        },
        { "Mofiqul/vscode.nvim", lazy = true },
    },

    -- Snacks a collection of QoL plugins
    {
        "folke/snacks.nvim",
        config = function()
            require("tt._plugins.snacks").setup()
        end,
    },

    -- Improve the default vim.ui interfaces
    {
        "stevearc/dressing.nvim",
        event = "VeryLazy",
        config = function()
            require("tt._plugins.dressing").setup()
        end,
    },

    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        event = "BufRead",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "SmiteshP/nvim-navic",
        },
        config = function()
            require("tt._plugins.lualine").setup()
        end,
    },

    -- Winbar
    {
        "utilyre/barbecue.nvim",
        event = "BufRead",
        dependencies = {
            "SmiteshP/nvim-navic",
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("tt._plugins.barbecue").setup()
        end,
    },

    -- Completely overhaul the UI
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
        },
        config = function()
            require("tt._plugins.noice").setup()
        end,
    },

    -- LSP related plugins
    {
        -- Portable package manager to install LSP & DAP servers, linters and formatters
        {
            "williamboman/mason.nvim",
            event = { "BufRead", "BufNewFile" },
            cmd = "Mason",
            keys = { "<leader>m" },
            build = ":MasonUpdate",
            dependencies = { "williamboman/mason-lspconfig.nvim" },
            config = function()
                require("tt._plugins.lsp.mason").setup()
            end,
        },
        -- Common configuration for LSP servers
        {
            "neovim/nvim-lspconfig",
            event = { "BufReadPre", "BufNewFile" },
            dependencies = {
                "SmiteshP/nvim-navic",
                "hrsh7th/cmp-nvim-lsp",
                {
                    "folke/lazydev.nvim",
                    dependencies = { "Bilal2453/luvit-meta" },
                    opts = {
                        ft = "lua",
                        cmd = "LazyDev",
                        library = {
                            { path = "luvit-meta/library", words = { "vim%.uv" } },
                            { path = "snacks.nvim", words = { "Snacks" } },
                        },
                    },
                },
            },
            config = function()
                require("tt._plugins.lsp.config").setup()
            end,
        },
        -- Incremental LSP based renaming with command preview
        {
            "smjonas/inc-rename.nvim",
            keys = { "<leader>rn", "<F2>" },
            config = function()
                require("inc_rename").setup {
                    show_message = false,
                }

                local utils = require "tt.utils"
                utils.map("n", { "<leader>rn", "<F2>" }, function()
                    return ":IncRename " .. vim.fn.expand "<cword>"
                end, { expr = true, desc = "Incremental LSP rename with preview" })
            end,
        },
        -- File operations using LSP
        {
            "antosha417/nvim-lsp-file-operations",
            event = "LspAttach",
            requires = {
                "nvim-lua/plenary.nvim",
                "nvim-neo-tree/neo-tree.nvim",
            },
            config = true,
        },
        -- Show current code context
        {
            "SmiteshP/nvim-navic",
            event = "BufReadPre",
            config = function()
                require("tt._plugins.lsp.nvim-navic").setup()
            end,
        },
        -- Better LSP utilities
        {
            "glepnir/lspsaga.nvim",
            event = "BufReadPre",
            config = function()
                require("tt._plugins.lsp.lsp-saga").setup()
            end,
        },
        -- Vscode like floating window with LSP locations
        {
            "dnlhc/glance.nvim",
            cmd = "Glance",
            keys = {
                {
                    "gr",
                    "<Cmd>Glance references<CR>",
                    desc = "Glance references",
                },
            },
            opts = {
                border = { enable = true },
            },
        },
        -- Pretty diagnostics
        {
            "rachartier/tiny-inline-diagnostic.nvim",
            event = "BufRead",
            config = function()
                require("tiny-inline-diagnostic").setup {
                    options = {
                        multilines = true,
                    },
                }
            end,
        },
        -- Sidebar with LSP symbols
        {
            "oskarrrrrrr/symbols.nvim",
            keys = {
                { "<leader>ss", "<Cmd>SymbolsToggle<CR>", mode = "n", desc = "Toggle the symbols sidebar" },
            },
            config = function()
                local recipes = require "symbols.recipes"
                require("symbols").setup(recipes.DefaultFilters, {
                    sidebar = {
                        auto_peek = true,
                        close_on_goto = true,
                        cursor_follow = false,
                        keymaps = {
                            ["go"] = "goto-symbol",
                            ["P"] = "open-preview",
                        },
                    },
                    providers = {
                        lsp = {
                            kinds = {
                                default = require("tt.icons").kind,
                            },
                        },
                    },
                })
            end,
        },
    },

    -- Git related plugins
    {
        -- Git integrations for buffers
        {
            "lewis6991/gitsigns.nvim",
            event = { "BufRead", "BufNewFile" },
            dependencies = "nvim-lua/plenary.nvim",
            config = function()
                require("tt._plugins.git.gitsigns").setup()
            end,
        },
        -- Better diff view interface and file history
        {
            "sindrets/diffview.nvim",
            cmd = {
                "DiffviewOpen",
                "DiffviewClose",
                "DiffviewFileHistory",
            },
            init = function()
                vim.cmd.cnoreabbrev "dvo DiffviewOpen"
                vim.cmd.cnoreabbrev "dvc DiffviewClose"
                vim.cmd.cnoreabbrev "dvf DiffviewFileHistory"
            end,
            config = function()
                require("tt._plugins.git.diffview").setup()
            end,
        },
        -- Popup about the commit message under cursor
        {
            "rhysd/git-messenger.vim",
            keys = "<leader>gm",
            config = function()
                require("tt._plugins.git.git-messenger").setup()
            end,
        },
        -- Generate shareable git file permalinks
        {
            "ruifm/gitlinker.nvim",
            keys = {
                "<leader>gy",
                "<leader>go",
                "<leader>gO",
                "<leader>gY",
            },
            dependencies = "nvim-lua/plenary.nvim",
            config = function()
                require("tt._plugins.git.gitlinker").setup()
            end,
        },
        -- More pleasant editing experience on commit messages
        {
            "rhysd/committia.vim",
            ft = "gitcommit",
            config = function()
                vim.g.committia_min_window_width = 140
                vim.g.committia_edit_window_width = 90
            end,
        },
        -- Visualize and fix merge conflicts
        {
            "akinsho/git-conflict.nvim",
            event = "BufRead",
            config = function()
                require("tt._plugins.git.git-conflict").setup()
            end,
        },
    },

    -- Autocomplete menu and snippets
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-nvim-lua",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "saadparwaiz1/cmp_luasnip",
            {
                "L3MON4D3/LuaSnip",
                dependencies = {
                    "tsakirist/friendly-snippets",
                    config = function()
                        require("luasnip.loaders.from_vscode").lazy_load()
                    end,
                },
                config = function()
                    require("luasnip").setup {
                        history = true,
                        delete_check_events = "TextChanged",
                    }
                end,
            },
        },
        config = function()
            require("tt._plugins.nvim-cmp").setup()
        end,
    },

    -- Treesitter related plugins
    {
        "nvim-treesitter/nvim-treesitter",
        event = { "BufReadPost", "BufNewFile" },
        cmd = "TSUpdate",
        build = function()
            if not _G.HeadlessMode() then
                vim.cmd.TSUpdate()
            end
        end,
        dependencies = {
            { "nvim-treesitter/nvim-treesitter-textobjects" },
            { "nvim-treesitter/nvim-treesitter-refactor" },
            -- TODO: Replace with fork until it's merged to upstream
            -- https://github.com/RRethy/nvim-treesitter-endwise/issues/41
            { "metiulekm/nvim-treesitter-endwise" },
        },
        config = function()
            require("tt._plugins.treesitter").setup()
        end,
    },

    -- Lightweight powerful formatter plugin
    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        dependencies = { "mason.nvim" },
        init = function()
            require("tt._plugins.format.conform").init()
        end,
        config = function()
            require("tt._plugins.format.conform").setup()
        end,
    },

    -- Navigation enhancements
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        config = function()
            require("tt._plugins.flash").setup()
        end,
    },

    -- Surf easily through the document and move elements
    {
        "ziontee113/syntax-tree-surfer",
        keys = {
            "<leader>gt",
            "<M-j>",
            "<M-k>",
            "<M-J>",
            "<M-K>",
            "vm",
            "vn",
        },
        dependencies = "nvim-treesitter/nvim-treesitter",
        config = function()
            require("tt._plugins.syntax-tree-surfer").setup()
        end,
    },

    -- Tag important files
    {
        "cbochs/grapple.nvim",
        event = {
            "BufReadPost",
            "BufNewFile",
        },
        config = function()
            require("tt._plugins.grapple").setup()
        end,
    },

    --  Treesitter to autoclose and autorename html tags
    {
        "windwp/nvim-ts-autotag",
        dependencies = "nvim-treesitter/nvim-treesitter",
        ft = {
            "html",
            "javascript",
            "javascriptreact",
            "typescriptreact",
            "svelte",
            "vue",
        },
    },

    -- Documentation/annotation generator using Treesitter
    {
        "danymat/neogen",
        keys = "<leader>ng",
        dependencies = "nvim-treesitter/nvim-treesitter",
        config = function()
            require("tt._plugins.neogen").setup()
        end,
    },

    -- Telescope fuzzy finding
    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        keys = {
            "<leader>f",
            "<leader>T",
            "<leader>gb",
            "<leader>gv",
        },
        dependencies = {
            { "nvim-lua/plenary.nvim" },
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = vim.fn.executable "make" == 1 and "make" or "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && \
                    cmake --build build --config Release  &&  cmake --install build --prefix build",
            },
            { "fdschmidt93/telescope-egrepify.nvim" },
            { "tsakirist/telescope-lazy.nvim" },
        },
        config = function()
            require("tt._plugins.telescope").setup()
        end,
    },

    -- Smart and powerful comment plugin
    {
        "numToStr/Comment.nvim",
        keys = {
            { "gc", mode = { "n", "v" } },
            { "gb", mode = { "n", "v" } },
            { "<leader><leader>", mode = { "n", "v" } },
        },
        dependencies = { "folke/ts-comments.nvim" },
        config = function()
            require("tt._plugins.comment").setup()
        end,
    },

    -- Display indentation levels with lines
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = "BufReadPre",
        config = function()
            require("tt._plugins.indent-blankline").setup()
        end,
    },

    -- Highlight current context
    {
        "shellRaining/hlchunk.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            ---@type HlChunk.UserConf
            require("hlchunk").setup {
                chunk = {
                    enable = true,
                    style = {
                        { fg = "#806d9c" },
                        { fg = "#806d9c" },
                    },
                    delay = 50,
                    duration = 200,
                    textobject = "ii",
                },
            }
        end,
    },

    -- Surround mappings for enclosed text
    {
        "echasnovski/mini.surround",
        event = "BufRead",
        config = function()
            require("tt._plugins.mini-surround").setup()
        end,
    },

    -- Add extra text objects
    {
        "echasnovski/mini.ai",
        event = "BufRead",
        dependencies = { "echasnovski/mini.extra" },
        opts = function()
            local ai = require "mini.ai"
            local ai_extra = require "mini.extra"
            return {
                silent = true,
                n_lines = 500,
                custom_textobjects = {
                    o = ai.gen_spec.treesitter {
                        a = { "@block.outer", "@conditional.outer", "@loop.outer" },
                        i = { "@block.inner", "@conditional.inner", "@loop.inner" },
                    },
                    f = ai.gen_spec.treesitter { a = "@function.outer", i = "@function.inner" },
                    c = ai.gen_spec.treesitter { a = "@class.outer", i = "@class.inner" },
                    g = ai_extra.gen_ai_spec.buffer(),
                    N = ai_extra.gen_ai_spec.number(),
                },
            }
        end,
    },

    -- Align text interactively
    {
        "echasnovski/mini.align",
        event = "BufRead",
        keys = {
            { "ga", mode = { "v" } },
        },
        opts = {
            mappings = {
                start_with_preview = "ga",
            },
        },
    },

    -- Move lines easily in any direction
    {
        "echasnovski/mini.move",
        event = "BufRead",
        opts = {
            mappings = {
                -- Visual mode
                left = "<C-h>",
                right = "<C-l>",
                down = "<C-j>",
                up = "<C-k>",

                -- Normal mode
                line_left = "<C-h>",
                line_right = "<C-l>",
                line_down = "<C-j>",
                line_up = "<C-k>",
            },
        },
    },

    -- Automatically add and manage character pairs
    {
        "echasnovski/mini.pairs",
        event = "InsertEnter",
        opts = {},
    },

    -- File explorer tree
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        cmd = "Neotree",
        event = "VimEnter",
        keys = {
            "<leader>nf",
            "<leader>nt",
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        config = function()
            require("tt._plugins.neo-tree").setup()
        end,
    },

    -- File explorer like buffer
    {
        "stevearc/oil.nvim",
        cmd = "Oil",
        keys = { "<leader>fe" },
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("tt._plugins.oil").setup()
        end,
    },

    -- Session management
    {
        "stevearc/resession.nvim",
        lazy = true,
        cmd = {
            "SSave",
            "SDelete",
            "SLoad",
            "SLast",
        },
        config = function()
            require("tt._plugins.resession").setup()
        end,
    },

    -- Pretty list for showing diagnostics, references, quickfix & loclist
    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        keys = "<leader>t",
        dependencies = "nvim-tree/nvim-web-devicons",
        config = function()
            require("tt._plugins.trouble").setup()
        end,
    },

    -- Floating terminal
    {
        "akinsho/toggleterm.nvim",
        cmd = "ToggleTerm",
        keys = {
            "<leader>ft",
            "<leader>vt",
            "<leader>ht",
            "<leader>bt",
            "<leader>lt",
        },
        config = function()
            require("tt._plugins.toggleterm").setup()
        end,
    },

    -- Automatic change normal string to template string when ${} is typed
    {
        "axelvc/template-string.nvim",
        ft = {
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "python",
        },
        opts = {},
    },

    -- Peak lines easily with :<number>
    {
        "nacro90/numb.nvim",
        event = "BufRead",
        config = function()
            require("tt._plugins.numb").setup()
        end,
    },

    -- Search & Replace UI
    {
        "MagicDuck/grug-far.nvim",
        cmd = "GrugFar",
        keys = {
            "<leader>sr",
            "<leader>sw",
            "<leader>sf",
        },
        config = function()
            require("tt._plugins.grug-far").setup()
        end,
    },

    -- Create custom submodes and menus
    {
        "cathyprime/hydra.nvim",
        keys = {
            "<leader>w",
        },
        dependencies = "lewis6991/gitsigns.nvim",
        config = function()
            require("tt._plugins.hydra").setup()
        end,
    },

    -- Enhanced increment/decrement operations
    {
        "monaqa/dial.nvim",
        keys = {
            { "<C-a>", mode = { "n", "v" } },
            { "<C-x>", mode = { "n", "v" } },
            { "c<C-a>", mode = "n" },
            { "c<C-x>", mode = "n" },
        },
        config = function()
            require("tt._plugins.dial").setup()
        end,
    },

    -- Split/join blocks of code
    {
        "Wansmer/treesj",
        dependencies = "nvim-treesitter/nvim-treesitter",
        keys = "<leader>sj",
        config = function()
            require("tt._plugins.treesj").setup()
        end,
    },

    -- Resize windows easily
    {
        "mrjones2014/smart-splits.nvim",
        keys = {
            "<leader>rs",
            "<M-h>",
            "<M-l>",
            "<C-w>h",
            "<C-w>k",
            "<C-w>j",
            "<C-w>l",
        },
        config = function()
            require("tt._plugins.smart-splits").setup()
        end,
    },

    -- Color highlighter
    {
        "NvChad/nvim-colorizer.lua",
        event = "BufReadPre",
        config = function()
            require("colorizer").setup {
                user_default_options = {
                    names = false,
                    mode = "background",
                },
            }
        end,
    },

    -- Wrapper over UNIX shell commands
    {
        "chrisgrieser/nvim-genghis",
        dependencies = "stevearc/dressing.nvim",
        cmd = "Genghis",
        init = function()
            local cmds = {
                { name = "Chmodx", command = ":Genghis chmodx" },
                { name = "Delete", command = ":Genghis trashFile" },
                { name = "Duplicate", command = ":Genghis duplicateFile" },
                { name = "MoveRename", command = ":Genghis moveAndRenameFile" },
                { name = "MoveTo", command = ":Genghis moveToFolderInCwd" },
            }

            for _, cmd in ipairs(cmds) do
                vim.api.nvim_create_user_command(cmd.name, cmd.command, {})
            end
        end,
        opts = {},
    },

    -- Allows for writing and reading files with sudo permissions from within neovim
    {
        "lambdalisue/suda.vim",
        cmd = { "SudaWrite", "SudoWrite" },
        init = function()
            -- Create a 'SudoWrite' alias that uses 'SudaWrite' command
            vim.api.nvim_create_user_command("SudoWrite", "SudaWrite", {})
        end,
    },

    -- Automatically detect the indentation used in the file
    {
        "NMAC427/guess-indent.nvim",
        event = "BufReadPre",
        opts = {},
    },

    -- Improve Markdown rendering
    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = "markdown",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            code = {
                position = "right",
                width = "block",
                right_pad = 1,
                left_pad = 1,
            },
        },
    },

    -- Nice looking animation for the current buffer
    {
        "eandrju/cellular-automaton.nvim",
        cmd = "CellularAutomaton",
    },

    -- Minimal Eye-candy keys screencaster
    {
        "nvchad/showkeys",
        cmd = "ShowkeysToggle",
        opts = {
            maxkeys = 5,
            show_count = true,
            position = "top-right",
        },
    },

    -- Measure the startup-time of neovim
    {
        "dstein64/vim-startuptime",
        cmd = "StartupTime",
        config = function()
            vim.g.startuptime_tries = 10
        end,
    },

    -- Interacting with tests within neovim
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-neotest/neotest-plenary",
            "nvim-neotest/neotest-vim-test",
            "nvim-neotest/nvim-nio",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter",
            "marilari88/neotest-vitest",
            "thenbe/neotest-playwright",
            "nvim-neotest/neotest-python",
        },
        config = function()
            require("tt._plugins.neotest").setup()
        end,
    },

    -- Debugging inside Neovim
    {
        "mfussenegger/nvim-dap",

        dependencies = {
            -- fancy UI for the debugger
            {
                "rcarriga/nvim-dap-ui",
                -- stylua: ignore
                keys = {
                    { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Dap UI" },
                    { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
                },
                opts = {},
                config = function(_, opts)
                    -- setup dap config by VsCode launch.json file
                    -- require("dap.ext.vscode").load_launchjs()
                    local dap = require "dap"
                    local dapui = require "dapui"
                    dapui.setup(opts)
                    dap.listeners.after.event_initialized["dapui_config"] = function()
                        dapui.open {}
                    end
                    dap.listeners.before.event_terminated["dapui_config"] = function()
                        dapui.close {}
                    end
                    dap.listeners.before.event_exited["dapui_config"] = function()
                        dapui.close {}
                    end
                end,
            },

            -- virtual text for the debugger
            {
                "theHamsta/nvim-dap-virtual-text",
                opts = {},
            },

            -- mason.nvim integration
            {
                "jay-babu/mason-nvim-dap.nvim",
                dependencies = "mason.nvim",
                cmd = { "DapInstall", "DapUninstall" },
                opts = {
                    -- Makes a best effort to setup the various debuggers with
                    -- reasonable debug configurations
                    automatic_installation = true,

                    -- You can provide additional configuration to the handlers,
                    -- see mason-nvim-dap README for more information
                    handlers = {},

                    -- You'll need to check that you have the required things installed
                    -- online, please don't ask me how to install them :)
                    ensure_installed = {
                        -- Update this to ensure that you have the debuggers for the langs you want
                    },
                },
            },

            {
                "jbyuki/one-small-step-for-vimkind",
                config = function()
                    local dap = require "dap"
                    dap.adapters.nlua = function(callback, conf)
                        local adapter = {
                            type = "server",
                            host = conf.host or "127.0.0.1",
                            port = conf.port or 8086,
                        }
                        if conf.start_neovim then
                            local dap_run = dap.run
                            dap.run = function(c)
                                adapter.port = c.port
                                adapter.host = c.host
                            end
                            require("osv").run_this()
                            dap.run = dap_run
                        end
                        callback(adapter)
                    end
                    dap.configurations.lua = {
                        {
                            type = "nlua",
                            request = "attach",
                            name = "Run this file",
                            start_neovim = {},
                        },
                        {
                            type = "nlua",
                            request = "attach",
                            name = "Attach to running Neovim instance (port = 8086)",
                            port = 8086,
                        },
                    }
                end,
            },
        },

        -- stylua: ignore
        keys = {
            { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
            { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
            { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
            { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
            { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
            { "<leader>dg", function() require("dap").goto_() end, desc = "Go to line (no execute)" },
            { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
            { "<leader>dj", function() require("dap").down() end, desc = "Down" },
            { "<leader>dk", function() require("dap").up() end, desc = "Up" },
            { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
            { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
            { "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
            { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
            { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
            { "<leader>ds", function() require("dap").session() end, desc = "Session" },
            { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
            { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
            { "<leader>dd", function() require("osv").launch({port = 8086}) end, desc = "Launch the osv server in the debuggee" },
        },
        config = function()
            vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
            local icons = require "tt.icons"
            for name, sign in pairs(icons.dap) do
                -- Check if sign is already a table
                if type(sign) == "table" then
                    -- If it's a table, use it directly
                    vim.fn.sign_define(
                        "Dap" .. name,
                        { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
                    )
                else
                    -- If it's not a table, assume it's a string and create a table
                    vim.fn.sign_define("Dap" .. name, { text = sign, texthl = "DiagnosticInfo" })
                end
            end
        end,
    },

    -- Interact with Github Copilot through Neovim
    { "github/copilot.vim" },

    -- Install nvim-metals for Scala development
    {
        "scalameta/nvim-metals",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        ft = { "scala", "sbt", "java" },
        opts = function()
            local metals_config = require("metals").bare_config()
            metals_config.on_attach = function(_, _) end

            return metals_config
        end,
        config = function(self, metals_config)
            local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
            vim.api.nvim_create_autocmd("FileType", {
                pattern = self.ft,
                callback = function()
                    require("metals").initialize_or_attach(metals_config)
                end,
                group = nvim_metals_group,
            })
        end,
    },

    -- Git integration
    { "tpope/vim-fugitive" },
}

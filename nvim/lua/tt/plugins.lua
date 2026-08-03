return {
    -- Colorschemes
    {
        {
            "EdenEast/nightfox.nvim",
            config = function()
                require("tt._plugins.nightfox").setup()
            end,
        },
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
        -- `TermOpen` ensures the statusline is initialized when a terminal is the
        -- first buffer opened, since terminals don't fire `BufRead`.
        event = { "BufRead", "TermOpen" },
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "SmiteshP/nvim-navic",
        },
        config = function()
            require("tt._plugins.lualine").setup()
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
        -- Common configuration for LSP servers
        {
            "neovim/nvim-lspconfig",
            event = { "BufReadPre", "BufNewFile" },
            dependencies = {
                "SmiteshP/nvim-navic",
                {
                    "folke/lazydev.nvim",
                    dependencies = { "Bilal2453/luvit-meta" },
                    opts = {
                        ft = "lua",
                        cmd = "LazyDev",
                        library = {
                            { path = "luvit-meta/library", words = { "vim%.uv" } },
                            { path = "snacks.nvim", words = { "Snacks", "snacks" } },
                        },
                    },
                },
            },
            config = function()
                require("tt._plugins.lsp.config").setup()
            end,
        },
        -- Portable package manager to install LSP & DAP servers, linters and formatters
        {
            "williamboman/mason.nvim",
            event = { "BufRead", "BufNewFile" },
            cmd = "Mason",
            keys = { "<leader>m" },
            build = ":MasonUpdate",
            dependencies = {
                "williamboman/mason-lspconfig.nvim",
                "neovim/nvim-lspconfig",
            },
            config = function()
                require("tt._plugins.lsp.mason").setup()
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
        -- Better LSP utilities
        {
            "glepnir/lspsaga.nvim",
            event = "BufReadPre",
            config = function()
                require("tt._plugins.lsp.lsp-saga").setup()
            end,
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
        -- LSP diagnostics for all files
        {
            "artemave/workspace-diagnostics.nvim",
            opts = {},
            keys = {
                {
                    "<leader>wd",
                    function()
                        -- Populate diagnostics for all files and open Trouble diagnostics view
                        for _, client in ipairs(vim.lsp.get_clients()) do
                            require("workspace-diagnostics").populate_workspace_diagnostics(client, 0)
                        end
                        vim.cmd.Trouble "diagnostics_inline_preview"
                    end,
                    mode = "n",
                    desc = "Populate workspace diagnostics and open Trouble",
                },
            },
        },
        -- Display LSP inlay hints at the end of the line
        {
            "chrisgrieser/nvim-lsp-endhints",
            event = "LspAttach",
            init = function()
                require("tt.utils").map("n", "<leader>im", function()
                    require("lsp-endhints").toggle()
                end, { desc = "Toggle between different inlay hint modes" })
            end,
            opts = {
                autoEnableHints = false,
            },
        },
        {
            "yioneko/nvim-vtsls",
            ft = {
                "javascript",
                "javascriptreact",
                "typescript",
                "typescriptreact",
                "vue",
            },
            cmd = {
                "VtsExec",
                "VtsRename",
            },
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
        -- VSCode style diff
        {
            "esmuellert/codediff.nvim",
            dependencies = "MunifTanjim/nui.nvim",
            cmd = "CodeDiff",
            keys = {
                { "<leader>cd", "<Cmd>CodeDiff<CR>", mode = "n", desc = "Open CodeDiff" },
            },
            opts = {
                keymaps = {
                    view = {
                        toggle_explorer = "<leader>e",
                    },
                    explorer = {
                        select = "o",
                        toggle_view_mode = "<leader>v",
                        toggle_stage = "s",
                    },
                },
            },
        },
        -- Popup about the commit message under cursor
        {
            "rhysd/git-messenger.vim",
            keys = "<leader>gm",
            config = function()
                require("tt._plugins.git.git-messenger").setup()
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
        -- Git integration
        { "tpope/vim-fugitive" },
    },

    -- Autocomplete menu and snippets
    {
        "saghen/blink.cmp",
        event = "InsertEnter",
        version = "1.*",
        dependencies = {
            { "xzbdmw/colorful-menu.nvim", opts = {} },
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
            require("tt._plugins.blink-cmp").setup()
        end,
    },

    -- Treesitter related plugins
    {
        "nvim-treesitter/nvim-treesitter",
        version = false,
        branch = "main",
        cmd = { "TSInstall", "TSLog", "TSUninstall", "TSUpdate" },
        event = { "BufReadPost", "BufNewFile" },
        build = ":TSUpdate",
        enabled = function()
            if vim.fn.executable "tree-sitter" == 0 then
                vim.notify(
                    table.concat({
                        "Treesitter main branch requires 'tree-sitter' CLI to be installed.",
                        "See: https://github.com/tree-sitter/tree-sitter/blob/master/crates/cli/README.md",
                    }, "\n"),
                    "error"
                )
                return false
            end
            return true
        end,
        dependencies = {
            {
                "nvim-treesitter/nvim-treesitter-textobjects",
                branch = "main",
                config = function()
                    require("tt._plugins.treesitter").setup_treesitter_textobjects()
                end,
            },
            { "RRethy/nvim-treesitter-endwise" },
        },
        config = function()
            require("tt._plugins.treesitter").setup_treesitter()
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

    -- Move and swap code around in a syntax tree aware manner
    {
        "aaronik/treewalker.nvim",
        dependencies = "nvim-treesitter/nvim-treesitter",
        keys = {
            -- movement (normal and visual modes)
            { "<C-S-k>", "<cmd>Treewalker Up<cr>", mode = { "n", "v" }, desc = "Move up" },
            { "<C-S-j>", "<cmd>Treewalker Down<cr>", mode = { "n", "v" }, desc = "Move down" },
            { "<C-S-h>", "<cmd>Treewalker Left<cr>", mode = { "n", "v" }, desc = "Move left" },
            { "<C-S-l>", "<cmd>Treewalker Right<cr>", mode = { "n", "v" }, desc = "Move right" },

            -- swapping (normal mode only)
            { "<C-k>", "<cmd>Treewalker SwapUp<cr>", mode = "n", desc = "Swap node up" },
            { "<C-j>", "<cmd>Treewalker SwapDown<cr>", mode = "n", desc = "Swap node down" },
            { "<C-h>", "<cmd>Treewalker SwapLeft<cr>", mode = "n", desc = "Swap node left" },
            { "<C-l>", "<cmd>Treewalker SwapRight<cr>", mode = "n", desc = "Swap node right" },
        },
        opts = {},
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

    -- Surround mappings for enclosed text
    {
        "nvim-mini/mini.surround",
        event = "BufRead",
        config = function()
            require("tt._plugins.mini-surround").setup()
        end,
    },

    -- Add extra text objects
    {
        "nvim-mini/mini.ai",
        event = "BufRead",
        dependencies = { "nvim-mini/mini.extra" },
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
        "nvim-mini/mini.align",
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
        "nvim-mini/mini.move",
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

    -- File explorer like buffer
    {
        "stevearc/oil.nvim",
        cmd = "Oil",
        keys = { "<leader>e" },
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
        keys = { "<leader>t", "gr", "gi", "<C-LeftMouse>" },
        dependencies = "nvim-tree/nvim-web-devicons",
        config = function()
            require("tt._plugins.trouble").setup()
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

    -- Fancy LSP symbol picker mimicking Zed editor
    {
        "bassamsdata/namu.nvim",
        cmd = "Namu",
        keys = { "<leader>fs", "<leader>fC" },
        config = function()
            require("tt._plugins.namu").setup()
        end,
    },

    -- Search & Replace UI
    {
        "MagicDuck/grug-far.nvim",
        cmd = "GrugFar",
        keys = {
            "<leader>sr",
            "<leader>sW",
            "<leader>sf",
        },
        config = function()
            require("tt._plugins.grug-far").setup()
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
        event = "VeryLazy",
        keys = {
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

    -- Java development utilities
    {
        "mfussenegger/nvim-jdtls",
        ft = { "java" },
        dependencies = { "neovim/nvim-lspconfig" },
        config = function()
            require("tt._plugins.jdtls").setup()
        end,
    },

    -- Rust development utilities
    {
        "mrcjkb/rustaceanvim",
        version = "^7",
        lazy = false,
        ft = { "rust" },
        init = function()
            require("tt._plugins.rustaceanvim").setup()
        end,
    },

    -- Kotlin development utilities
    {
        "AlexandrosAlexiou/kotlin.nvim",
        ft = { "kotlin" },
        dependencies = { "mason.nvim", "mason-lspconfig.nvim", "oil.nvim" },
        config = function()
            require("kotlin").setup {
                root_markers = {
                    "gradlew",
                    ".git",
                    "mvnw",
                    "settings.gradle",
                },
                jvm_args = {
                    "-Xmx4G",
                    "-Xms4G",
                },
                inlay_hints = {
                    enabled = true, -- Enable inlay hints (auto-enable on LSP attach)
                    parameters = true, -- Show parameter names
                    parameters_compiled = true, -- Show compiled parameter names
                    parameters_excluded = false, -- Show excluded parameter names
                    types_property = true, -- Show property types
                    types_variable = true, -- Show local variable types
                    function_return = true, -- Show function return types
                    function_parameter = true, -- Show function parameter types
                    lambda_return = true, -- Show lambda return types
                    lambda_receivers_parameters = true, -- Show lambda receivers/parameters
                    value_ranges = true, -- Show value ranges
                    kotlin_time = true, -- Show kotlin.time warnings
                    call_chains = true, -- Show call-chain intermediate types
                },
            }
        end,
    },

    -- Full-text search powered by Tantivy
    {
        dir = "~/sources/sakuin.nvim",
        build = function()
            require("sakuin.install").build()
        end,
        dependencies = { "folke/snacks.nvim" },
        config = function()
            require("sakuin").setup {
                search = {
                    debounce = 0,
                },
                keymaps = {
                    search_cword = "<leader>sw",
                },
            }
        end,
    },
}

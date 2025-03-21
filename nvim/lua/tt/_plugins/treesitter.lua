local M = {}

function M.setup()
    -- Do not run setup when in headless mode
    if _G.HeadlessMode() then
        return
    end

    require("nvim-treesitter.configs").setup {
        modules = {},
        sync_install = false,
        auto_install = false,
        ignore_install = {},
        ensure_installed = {
            "bash",
            "c",
            "cmake",
            "comment",
            "cpp",
            "css",
            "dockerfile",
            "git_config",
            "git_rebase",
            "gitcommit",
            "gitignore",
            "html",
            "javascript",
            "jsdoc",
            "json",
            "lua",
            "luadoc",
            "make",
            "markdown",
            "markdown_inline",
            "python",
            "regex",
            "scss",
            "toml",
            "tsx",
            "typescript",
            "vim",
            "vimdoc",
            "yaml",
        },
        autopairs = {
            enable = true,
        },
        autotag = {
            enable = true,
        },
        endwise = {
            enable = true,
        },
        highlight = {
            enable = true,
            custom_captures = {},
            additional_vim_regex_highlighting = false,
        },
        indent = {
            enable = true,
            disable = { "c", "cpp", "lua" },
        },
        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = "gis",
                node_incremental = "ni",
                node_decremental = "nd",
                scope_incremental = "si",
            },
        },
        refactor = {
            highlight_definitions = {
                enable = true,
                clear_on_cursor_move = false,
            },
            highlight_current_scope = {
                enable = false,
            },
        },
        textobjects = {
            select = {
                enable = true,
                lookahead = true,
                keymaps = {
                    ["af"] = "@function.outer",
                    ["if"] = "@function.inner",
                    ["al"] = "@loop.outer",
                    ["il"] = "@loop.inner",
                    ["ac"] = "@conditional.outer",
                    ["ic"] = "@conditional.inner",
                    ["aC"] = "@class.outer",
                    ["iC"] = "@class.inner",
                },
            },
            swap = {
                enable = true,
                swap_next = {
                    ["<leader>sp"] = "@parameter.inner",
                    ["<leader>sm"] = "@function.outer",
                },
                swap_previous = {
                    ["<leader>sP"] = "@parameter.inner",
                    ["<leader>sM"] = "@function.outer",
                },
            },
            move = {
                enable = true,
                set_jumps = true,
                goto_next_start = {
                    ["]m"] = "@function.outer",
                    ["]C"] = "@class.outer",
                },
                goto_next_end = {
                    ["]M"] = "@function.outer",
                },
                goto_previous_start = {
                    ["[m"] = "@function.outer",
                    ["[C"] = "@class.outer",
                },
                goto_previous_end = {
                    ["[M"] = "@function.outer",
                },
            },
        },
    }
end

return M

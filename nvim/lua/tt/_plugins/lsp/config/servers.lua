local M = {}

-- Custom lsp server settings
M.lsp_servers = {
    astro = {},
    bashls = {},
    clangd = {
        capabilities = {
            -- https://github.com/jose-elias-alvarez/null-ls.nvim/issues/428
            offsetEncoding = { "utf-16" },
        },
    },
    cmake = {},
    cssls = {},
    eslint = {
        settings = {
            codeAction = {
                showDocumentation = false,
            },
        },
        on_attach = function(_, bufnr)
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = vim.api.nvim_create_augroup("tt.Eslint", { clear = true }),
                buffer = bufnr,
                command = "EslintFixAll",
                desc = "Fixes all eslint errors on save",
            })
        end,
    },
    graphql = { filetypes = {
        "graphql",
    } },
    kotlin_language_server = {
        filetypes = {
            "kotlin",
        },
        root_dir = function()
            return vim.fn.getcwd()
        end,
        settings = {
            kotlin = { compiler = { jvm = { target = "21" } } },
            hints = {
                typeHints = true,
                parameterHints = true,
                chainedHints = true,
            },
        },
    },
    lua_ls = {
        settings = {
            Lua = {
                completion = {
                    callSnippet = "Replace",
                },
                diagnostics = {
                    globals = {
                        "vim",
                        "jit",
                    },
                },
                hint = {
                    enable = true,
                    arrayIndex = "Disable", -- "Enable", "Auto", "Disable"
                    await = true,
                    paramName = "All", -- "All", "Literal", "Disable"
                    paramType = true,
                    semicolon = "Disable", -- "All", "SameLine", "Disable"
                    setType = true,
                },
                runtime = {
                    version = "LuaJIT",
                },
                telemetry = {
                    enable = false,
                },
                workspace = {
                    checkThirdParty = false,
                    library = {
                        vim.env.VIMRUNTIME,
                    },
                },
            },
        },
    },
    pyright = {},
    rust_analyzer = {
        settings = {
            ["rust-analyzer"] = {
                check = {
                    command = "clippy",
                },
                checkOnSave = true,
            },
        },
    },
    ts_ls = {
        init_options = {
            embeddedLanguages = {
                html = true,
            },
            plugins = {
                {
                    name = "@vue/typescript-plugin",
                    location = "node_modules/@vue/typescript-plugin",
                    languages = { "javascript", "typescript", "vue" },
                    enableForWorkspaceTypeScriptVersions = true,
                },
            },
        },
        filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
        settings = {
            typescript = {
                inlayHints = {
                    includeInlayParameterNameHints = "all",
                    includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                    includeInlayFunctionParameterTypeHints = true,
                    includeInlayVariableTypeHints = true,
                    includeInlayPropertyDeclarationTypeHints = true,
                    includeInlayFunctionLikeReturnTypeHints = true,
                    includeInlayEnumMemberValueHints = true,
                },
            },
            javascript = {
                inlayHints = {
                    includeInlayParameterNameHints = "all",
                    includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                    includeInlayFunctionParameterTypeHints = true,
                    includeInlayVariableTypeHints = true,
                    includeInlayPropertyDeclarationTypeHints = true,
                    includeInlayFunctionLikeReturnTypeHints = true,
                    includeInlayEnumMemberValueHints = true,
                },
            },
        },
    },
    yamlls = {},
    volar = {
        filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
        init_options = {
            vue = {
                hybridMode = true,
            },
        },
    },
}

-- List of servers that should be manually installed via Mason
M.mason_servers = {
    "shellcheck",
}

function M.setup()
    local common_opts = {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
    }

    for _, server in ipairs(vim.tbl_keys(M.lsp_servers)) do
        local server_opts = vim.tbl_deep_extend("force", common_opts, M.lsp_servers[server])
        require("lspconfig")[server].setup(server_opts)
    end
end

return M

local M = {}

-- Workaround for on_attach not firing properly when overridden
-- https://github.com/neovim/nvim-lspconfig/issues/3837#issuecomment-2868987087
local base_on_attach = {
    eslint = vim.lsp.config.eslint.on_attach,
}

-- Custom lsp server settings
M.lsp_servers = {
    astro = {},
    bashls = {},
    clangd = {
        cmd = {
            "clangd",
            "-j=4",
            "--background-index",
            "--completion-style=detailed",
            "--header-insertion=iwyu",
            "--header-insertion-decorators",
            "--pch-storage=memory",
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
        on_attach = function(client, bufnr)
            base_on_attach.eslint(client, bufnr)
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = vim.api.nvim_create_augroup("tt.Eslint", { clear = false }),
                buffer = bufnr,
                command = "LspEslintFixAll",
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
                    arrayIndex = "Disable",
                    await = true,
                    paramName = "All",
                    paramType = true,
                    semicolon = "Disable",
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

local function make_client_capabilities()
    local capabilities = {
        textDocument = {
            foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true,
            },
            semanticTokens = {
                multilineTokenSupport = true,
            },
            completion = {
                completionItem = {
                    snippetSupport = true,
                },
            },
        },
    }
    return require("blink.cmp").get_lsp_capabilities(capabilities)
end

function M.setup()
    local capabilities = make_client_capabilities()

    -- Setup settings for all servers
    vim.lsp.config("*", {
        capabilities = capabilities,
    })

    -- Setup settings per server and enable auto start
    for _, server in ipairs(vim.tbl_keys(M.lsp_servers)) do
        vim.lsp.config(server, M.lsp_servers[server])
        vim.lsp.enable(server)
    end
end

return M

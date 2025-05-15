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
    jdtls = {},
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
    vtsls = {
        on_attach = function(_, bufnr)
            local conform = require "tt._plugins.format.conform"
            conform.add_pre_format_handler(bufnr, function()
                vim.cmd "VtsExec remove_unused_imports"
            end)
        end,
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
        filetypes = { "vue" },
        init_options = {
            vue = {
                hybridMode = false,
            },
            languageFeatures = {
                implementation = true,
                references = true,
                definition = true,
                typeDefinition = true,
                callHierarchy = true,
                hover = true,
                rename = true,
                renameFileRefactoring = true,
                signatureHelp = true,
                codeAction = true,
                workspaceSymbol = true,
                completion = {
                    defaultTagNameCase = "both",
                    defaultAttrNameCase = "kebabCase",
                    getDocumentNameCasesRequest = false,
                    getDocumentSelectionRequest = false,
                },
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

    -- Define servers to exclude from config
    local excluded_servers = { jdtls = true }

    -- Setup settings per server and enable auto start
    local function configure_server(server)
        if not excluded_servers[server] then
            vim.lsp.config(server, M.lsp_servers[server])
            vim.lsp.enable(server)
        end
    end

    vim.tbl_map(configure_server, vim.tbl_keys(M.lsp_servers))
end

return M

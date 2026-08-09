local format_utils = require "tt._plugins.format.utils"

local M = {}

--- Cache, keyed by project root, of detection results.
---@type table<string, table<string, string[]>>
local formatter_cache = {}

--- Resolves the project root of the given buffer, keyed off the .git directory.
---@param bufnr Buffer
---@return string
local function project_root(bufnr)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local start = fname ~= "" and vim.fs.dirname(fname) or (vim.uv or vim.loop).cwd()

    local git = vim.fs.find(".git", { upward = true, path = start })[1]
    return git and vim.fs.dirname(git) or start
end

--- Returns the concatenated contents of the project's root build files.
---@param root string
---@return string
local function build_files_content(root)
    local contents = {}
    for _, name in ipairs { "pom.xml", "build.gradle", "build.gradle.kts" } do
        local path = root .. "/" .. name
        if vim.fn.filereadable(path) == 1 then
            table.insert(contents, table.concat(vim.fn.readfile(path), "\n"))
        end
    end
    return table.concat(contents, "\n")
end

--- Checks whether the project's root .editorconfig declares IntelliJ code-style
--- properties for the given language (e.g. ij_java_*, ij_kotlin_*).
---@param root string
---@param lang string
---@return boolean
local function editorconfig_has_intellij_style(root, lang)
    local path = root .. "/.editorconfig"
    if vim.fn.filereadable(path) ~= 1 then
        return false
    end
    local content = table.concat(vim.fn.readfile(path), "\n")
    return content:find("ij_" .. lang .. "_", 1, true) ~= nil
end

--- Detects whether the buffer belongs to a project that prefers IntelliJ LSP formatting,
--- marked by an `.intellij-format` file in the project root. Can also be forced per
--- buffer/session with `vim.b.format_with_intellij` / `vim.g.format_with_intellij`.
---@param bufnr Buffer
---@return boolean?
local function forced_intellij(bufnr)
    if vim.b[bufnr].format_with_intellij ~= nil then
        return vim.b[bufnr].format_with_intellij
    end
    if vim.g.format_with_intellij ~= nil then
        return vim.g.format_with_intellij
    end
    if vim.fn.filereadable(project_root(bufnr) .. "/.intellij-format") == 1 then
        return true
    end
    return nil
end

--- Auto-detects the Java formatters for the buffer's project:
---  1. explicit override (vim.b/vim.g/.intellij-format) -> IntelliJ LSP
---  2. spotless palantirJavaFormat in build files       -> palantir-java-format
---  3. spotless googleJavaFormat in build files         -> google-java-format
---  4. ij_java_* properties in root .editorconfig       -> IntelliJ LSP
---  5. default                                          -> google-java-format
---@param bufnr Buffer
---@return string[]
local function java_formatters(bufnr)
    local forced = forced_intellij(bufnr)
    if forced ~= nil then
        return forced and {} or { "google-java-format" }
    end

    local root = project_root(bufnr)
    formatter_cache[root] = formatter_cache[root] or {}
    if formatter_cache[root].java == nil then
        local build = build_files_content(root)
        if build:find("palantirJavaFormat", 1, true) then
            formatter_cache[root].java = { "palantir-java-format" }
        elseif build:find("googleJavaFormat", 1, true) then
            formatter_cache[root].java = { "google-java-format" }
        elseif editorconfig_has_intellij_style(root, "java") then
            formatter_cache[root].java = {} -- IntelliJ LSP via lsp fallback
        else
            formatter_cache[root].java = { "google-java-format" }
        end
    end
    return formatter_cache[root].java
end

--- Auto-detects the Kotlin formatters for the buffer's project:
---  1. explicit override (vim.b/vim.g/.intellij-format) -> IntelliJ LSP
---  2. ktfmt in build files (spotless/plugin)           -> ktfmt
---  3. ij_kotlin_* properties in root .editorconfig     -> IntelliJ LSP
---  4. default                                          -> ktfmt
---@param bufnr Buffer
---@return string[]
local function kotlin_formatters(bufnr)
    local forced = forced_intellij(bufnr)
    if forced ~= nil then
        return forced and {} or { "ktfmt" }
    end

    local root = project_root(bufnr)
    formatter_cache[root] = formatter_cache[root] or {}
    if formatter_cache[root].kotlin == nil then
        local build = build_files_content(root)
        if build:find("ktfmt", 1, true) then
            formatter_cache[root].kotlin = { "ktfmt" }
        elseif editorconfig_has_intellij_style(root, "kotlin") then
            formatter_cache[root].kotlin = {} -- IntelliJ LSP via lsp fallback
        else
            formatter_cache[root].kotlin = { "ktfmt" }
        end
    end
    return formatter_cache[root].kotlin
end

--- Formats the current buffer, with optional customization through specified opts.
---@param opts? conform.FormatOpts
function M.format(opts)
    ---@type conform.FormatOpts
    local format_opts = vim.tbl_extend("force", {
        async = false,
        lsp_fallback = true,
        timeout_ms = 2500,
    }, opts or {})
    format_utils.run_pre_format_handlers(format_opts.bufnr)
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
--- If no bufnr is provided or 0, it will use the current buffer.
---@param bufnr? Buffer
---@param handler fun()
function M.add_pre_format_handler(bufnr, handler)
    format_utils.add_pre_format_handler(bufnr, handler)
end

--- Removes a handler from the pre format handlers table for the given bufnr.
--- If no bufnr is provided or 0, it will use the current buffer.
---@param bufnr? Buffer
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
            go = { "goimports", "gofumpt" },
            graphql = { "prettierd" },
            java = java_formatters,
            kotlin = kotlin_formatters,
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
            ["palantir-java-format"] = {
                command = "palantir-java-format",
                -- `--palantir` selects the Palantir style (4-space, 120-col); without it the CLI runs in
                -- google-java-format compatibility mode (2-space). `--skip-reflowing-long-strings` matches
                -- spotless, which does not break long string literals across lines. Together these produce
                -- byte-identical output to the project's `spotless:apply`.
                args = { "--palantir", "--skip-reflowing-long-strings", "-" },
                stdin = true,
            },
            ktfmt = {
                prepend_args = { "--kotlinlang-style" },
            },
            shfmt = {
                prepend_args = { "-i", "4", "-bn", "-ci", "-sr" },
            },
        },
        format_on_save = function(bufnr)
            if vim.b.disable_autoformat then
                return
            end
            local filetype = vim.bo[bufnr].filetype
            if format_utils.should_format(filetype, bufnr) then
                M.format { bufnr = bufnr }
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

    utils.map("n", "<leader>tF", function()
        local bufnr = vim.api.nvim_get_current_buf()
        -- Flip the effective state: IntelliJ is in use when no CLI formatters resolve.
        local formatters = require("conform").list_formatters_to_run(bufnr)
        vim.b[bufnr].format_with_intellij = not vim.tbl_isempty(formatters)
        vim.notify(
            string.format(
                "Formatting with %s for buffer #%d",
                vim.b[bufnr].format_with_intellij and "IntelliJ LSP" or "conform CLI formatters",
                bufnr
            ),
            vim.log.levels.INFO,
            { title = "Format" }
        )
    end, { desc = "Toggle between IntelliJ LSP and CLI formatters for the current buffer" })
end

return M

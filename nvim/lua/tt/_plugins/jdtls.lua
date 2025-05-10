local M = {}

function M.setup()
    -- Create an autocommand group for jdtls
    local group = vim.api.nvim_create_augroup("jdtls", { clear = true })

    -- Set up the autocmd to configure JDTLS when a Java file is opened
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        callback = function()
            M.setup_jdtls()
        end,
        group = group,
    })

    vim.api.nvim_create_user_command("JdtCleanWorkspace", function()
        M.clean_workspace()
    end, { desc = "Clean JDTLS workspace for current project" })
end

function M.clean_workspace()
    local home = os.getenv "HOME"
    local current_dir = vim.fn.getcwd()
    local project_name = vim.fn.fnamemodify(current_dir, ":p:h:t")
    local workspace_dir = home .. "/.cache/jdtls-workspaces/" .. project_name

    vim.notify("Cleaning workspace for " .. project_name, vim.log.levels.INFO)

    for _, client in ipairs(vim.lsp.get_clients { name = "jdtls" }) do
        vim.notify("Stopping JDTLS...", vim.log.levels.INFO)
        vim.lsp.stop_client(client.id)
        vim.cmd "sleep 500m" -- Give it time to fully shut down
    end

    -- Remove lock file specifically
    local lock_file = workspace_dir .. "/.metadata/.lock"
    if vim.fn.filereadable(lock_file) == 1 then
        vim.fn.delete(lock_file)
        vim.notify("Removed workspace lock file", vim.log.levels.INFO)
    end

    -- Check for and remove the entire .metadata directory if needed
    local metadata_dir = workspace_dir .. "/.metadata"
    if vim.fn.isdirectory(metadata_dir) == 1 then
        vim.fn.system("rm -rf " .. metadata_dir)
        vim.notify("Removed .metadata directory", vim.log.levels.INFO)
    end

    vim.notify("Workspace cleaned. Ready to restart JDTLS.", vim.log.levels.INFO)
end

function M.setup_jdtls()
    local jdtls = require "jdtls"
    local home = os.getenv "HOME"

    -- Find root directory for the project
    local root_markers = {
        ".git",
        "mvnw",
        ".mvn",
        "gradlew",
    }
    local root_dir = require("jdtls.setup").find_root(root_markers)

    -- If no root found, use current directory
    if not root_dir then
        root_dir = vim.fn.getcwd()
    end

    -- Project name based on root directory name
    local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
    local workspace_dir = home .. "/.cache/jdtls-workspaces/" .. project_name

    -- Ensure workspace directory exists
    vim.fn.mkdir(workspace_dir, "p")

    -- Simplified: Use fixed path for JDTLS instead of mason's get_install_path
    local jdtls_path = home .. "/.local/share/nvim/mason/packages/jdtls"

    -- Check if the JDTLS path exists
    if vim.fn.isdirectory(jdtls_path) ~= 1 then
        vim.notify("JDTLS installation not found at: " .. jdtls_path, vim.log.levels.ERROR)
        return
    end

    -- Set up Lombok
    local lombok_path = home .. "/.local/share/nvim/java-libs/lombok.jar"
    if vim.fn.filereadable(lombok_path) == 0 then
        vim.notify("Lombok installation not found at: " .. lombok_path, vim.log.levels.ERROR)
    end

    -- Determine OS-specific configuration
    local os_config
    if vim.fn.has "mac" == 1 then
        os_config = "config_mac"
    elseif vim.fn.has "unix" == 1 then
        os_config = "config_linux"
    else
        os_config = "config_win"
    end

    -- Find available bundles
    local bundles = {}
    table.insert(bundles, lombok_path) -- Add Lombok jar

    -- Java debug adapter
    local java_debug_path = home .. "/.local/share/nvim/java-debug"
    if vim.fn.isdirectory(java_debug_path) == 1 then
        local debug_bundles = vim.split(
            vim.fn.glob(
                java_debug_path .. "/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar"
            ),
            "\n"
        )
        for _, bundle in ipairs(debug_bundles) do
            if bundle ~= "" then
                table.insert(bundles, bundle)
            end
        end
    end

    -- Test bundles (vscode-java-test)
    local java_test_path = home .. "/.local/share/nvim/vscode-java-test"
    if vim.fn.isdirectory(java_test_path) == 1 then
        local test_bundles = vim.split(vim.fn.glob(java_test_path .. "/server/*.jar"), "\n")
        for _, bundle in ipairs(test_bundles) do
            if bundle ~= "" then
                table.insert(bundles, bundle)
            end
        end
    end

    -- Simplified: Use direct path to java executable
    local java_cmd = "/usr/bin/java"

    -- JDTLS configuration
    local config = {
        cmd = {
            java_cmd,
            "-Declipse.application=org.eclipse.jdt.ls.core.id1",
            "-Dosgi.bundles.defaultStartLevel=4",
            "-Declipse.product=org.eclipse.jdt.ls.core.product",
            "-Dlog.protocol=true",
            "-Dlog.level=ALL",
            "-Xmx2g",
            "-Dosgi.locking=none",
            "-javaagent:" .. lombok_path,
            "--add-modules=ALL-SYSTEM",
            "--add-opens",
            "java.base/java.util=ALL-UNNAMED",
            "--add-opens",
            "java.base/java.lang=ALL-UNNAMED",
            "-jar",
            vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
            "-configuration",
            jdtls_path .. "/" .. os_config,
            "-data",
            workspace_dir,
        },
        root_dir = root_dir,
        settings = {
            java = {
                configuration = {
                    updateBuildConfiguration = "automatic",
                    maven = {
                        downloadSources = true,
                        updateSnapshots = true,
                        userSettings = home .. "/.m2/settings.xml",
                    },
                },
                format = { enabled = true },
                completion = {
                    favoriteStaticMembers = {
                        "org.junit.Assert.*",
                        "org.junit.jupiter.api.Assertions.*",
                        "java.util.Objects.requireNonNull",
                    },
                },
                sources = {
                    organizeImports = {
                        starThreshold = 9999,
                        staticStarThreshold = 9999,
                    },
                },
                implementationsCodeLens = { enabled = true },
                referencesCodeLens = { enabled = true },
                inlayHints = {
                    parameterNames = { enabled = "all" },
                },
            },
        },
        init_options = {
            bundles = bundles,
        },
        capabilities = vim.lsp.protocol.make_client_capabilities(),
        on_attach = function(_, _)
            local utils = require "tt.utils"
            utils.map("n", "<leader>jo", jdtls.organize_imports, { desc = "Organize imports" })
            utils.map("n", "<leader>jt", jdtls.test_nearest_method, { desc = "Test nearest method" })
            utils.map("n", "<leader>jT", jdtls.test_class, { desc = "Test class" })
            utils.map("n", "<leader>jv", jdtls.extract_variable, { desc = "Extract variable" })
            utils.map("n", "<leader>jc", jdtls.extract_constant, { desc = "Extract constant" })
            utils.map("v", "<leader>jm", function()
                jdtls.extract_method { visual = true }
            end, { desc = "Extract method" })

            -- Connect DAP if java-debug is available
            if vim.fn.isdirectory(home .. "/.local/share/nvim/java-debug") == 1 then
                require("jdtls").setup_dap {
                    hotcodereplace = "auto",
                    config_overrides = {},
                }
                require("jdtls.dap").setup_dap_main_class_configs()
            end
        end,
    }

    -- Update capabilities for nvim-cmp if available
    local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if ok then
        config.capabilities = cmp_lsp.default_capabilities(config.capabilities)
    end

    -- Start the JDTLS server
    jdtls.start_or_attach(config)
end

return M

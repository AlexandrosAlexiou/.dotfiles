local M = {}

local utils = require "tt.utils"
local custom_pickers = require "tt._plugins.snacks.custom_pickers"

local function setup_generic_keymaps()
    utils.map("n", { "<leader>nn", "<leader>nh" }, function()
        Snacks.notifier.show_history()
    end, { desc = "Show notification history" })

    utils.map("n", "<leader>nd", function()
        Snacks.notifier.hide()
    end, { desc = "Hide all notifications" })

    utils.map("n", "<leader>bd", function()
        -- In a goto-split window (gv/gh), close the window instead of
        -- swapping in the previous buffer (avoids duplicate splits)
        if vim.w.goto_split and #vim.api.nvim_tabpage_list_wins(0) > 1 then
            local buf = vim.api.nvim_get_current_buf()
            vim.api.nvim_win_close(0, false)
            -- Delete the buffer too if no other window shows it
            if vim.fn.getbufinfo(buf)[1] and #vim.fn.getbufinfo(buf)[1].windows == 0 then
                Snacks.bufdelete.delete { buf = buf }
            end
            return
        end
        Snacks.bufdelete.delete()
    end, { desc = "Delete current buffer" })

    utils.map("n", "<leader>bD", function()
        Snacks.bufdelete.delete { force = true }
    end, { desc = "Force delete current buffer" })

    utils.map("n", "<leader>s,", Snacks.scratch.open, { desc = "Open scratch buffer" })

    utils.map("n", "<F1>", Snacks.zen.zen, { desc = "Toggle Zen mode" })

    utils.map({ "n", "v" }, "<leader>go", Snacks.gitbrowse.open, { desc = "Git browse file" })

    Snacks.toggle.dim():map("<leader>sd", { desc = "Toggle dim mode" })
end

local function setup_picker_keymaps()
    utils.map("n", "<leader>F", Snacks.picker.pick, { desc = "Snacks pickers" })
    utils.map("n", "<leader>fa", Snacks.picker.autocmds, { desc = "Search autocommands" })
    utils.map("n", "<leader>fb", Snacks.picker.buffers, { desc = "Search for open buffers" })
    utils.map("n", "<leader>fc", Snacks.picker.commands, { desc = "Search commands" })
    utils.map("n", "<leader>fe", Snacks.picker.explorer, { desc = "Snacks explorer" })
    utils.map("n", "<leader>ff", Snacks.picker.files, { desc = "Search for files" })
    utils.map("n", "<leader>fg", Snacks.picker.grep, { desc = "Live grep" })
    utils.map("n", "<leader>fh", Snacks.picker.help, { desc = "Search for help tags" })
    utils.map("n", "<leader>fl", Snacks.picker.lines, { desc = "Search for lines in current buffer" })
    utils.map("n", "<leader>fL", Snacks.picker.lazy, { desc = "Search for Lazy spec" })
    utils.map("n", "<leader>fm", Snacks.picker.keymaps, { desc = "Search keymaps" })
    utils.map("n", "<leader>fn", Snacks.picker.notifications, { desc = "Search for notifications" })
    utils.map("n", "<leader>fo", Snacks.picker.recent, { desc = "Search for recent files" })
    utils.map({ "n", "v" }, "<leader>fw", Snacks.picker.grep_word, { desc = "Search for visual selection or word" })
    utils.map("n", "<leader>fF", Snacks.picker.git_files, { desc = "Search for git files" })
    utils.map("n", "<leader>fG", Snacks.picker.git_grep, { desc = "Search for git files" })
    utils.map("n", "<leader>fH", Snacks.picker.highlights, { desc = "Search for highlights" })
    utils.map("n", "<leader>fM", Snacks.picker.man, { desc = "Search for man pages" })
    utils.map("n", "<leader>fP", Snacks.picker.projects, { desc = "Search for projects" })
    utils.map("n", "<leader>f:", Snacks.picker.command_history, { desc = "Search for command history" })
    utils.map("n", "<leader>f/", Snacks.picker.search_history, { desc = "Search for search history" })
    utils.map("n", "<leader>bs", Snacks.picker.grep_buffers, { desc = "Live grep in open buffers" })
    utils.map("n", "<leader>so", Snacks.picker.smart, { desc = "Smart open" })

    utils.map("n", "<leader>G", custom_pickers.git_pickers, { desc = "Snacks git pickers" })

    utils.map("n", "<leader>fv", function()
        custom_pickers.config_action "files"
    end, { desc = "Find files in config" })

    utils.map("n", "<leader>gv", function()
        custom_pickers.config_action "grep"
    end, { desc = "Grep files in config" })

    utils.map("n", "<leader>fS", custom_pickers.show_sessions, { desc = "Search for saved sessions" })
end

local function setup_lazygit_keymaps()
    utils.map("n", { "<leader>lg", "<leader>lt" }, function()
        Snacks.lazygit()
    end, { desc = "Open Lazygit" })
end

function M.setup()
    local setups = {
        setup_generic_keymaps,
        setup_picker_keymaps,
        setup_lazygit_keymaps(),
    }

    for _, setup in ipairs(setups) do
        setup()
    end
end

return M

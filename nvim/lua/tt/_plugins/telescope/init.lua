local actions = require "telescope.actions"
local actions_layout = require "telescope.actions.layout"
local telescope_config = require "telescope.config"
local trouble = require "trouble.sources.telescope"

local M = {}

--- Extend default telescope vimgrep_arguments.
local function extended_vimgrep_arguments()
    local vimgrep_arguments = telescope_config.values.vimgrep_arguments
    table.insert(vimgrep_arguments, "--follow")
    return vimgrep_arguments
end

function M.setup()
    require("telescope").setup {
        defaults = {
            dynamic_preview_title = true,
            selection_caret = "❯ ",
            prompt_prefix = "  ",
            winblend = 0,
            wrap_results = false,
            initial_mode = "insert",
            layout_strategy = "horizontal",
            layout_config = {
                prompt_position = "bottom",
                horizontal = {
                    width = { padding = 0.1 },
                    height = { padding = 0.1 },
                    preview_width = 0.5,
                    mirror = false,
                },
                vertical = {
                    width = { padding = 0.1 },
                    height = { padding = 0.1 },
                    preview_height = 0.65,
                    mirror = false,
                },
            },
            path_display = { "filename_first" },
            sorting_strategy = "descending",
            set_env = { ["COLORTERM"] = "truecolor" },
            file_ignore_patterns = { "node_modules", "%.git", "%.cache" },
            vimgrep_arguments = extended_vimgrep_arguments(),
            mappings = {
                i = {
                    ["<C-j>"] = actions.move_selection_next,
                    ["<C-k>"] = actions.move_selection_previous,
                    ["<CR>"] = actions.select_default + actions.center,
                    ["<C-r>"] = trouble.open,
                    ["<C-t>"] = actions.select_tab,
                    ["<C-q>"] = actions.close,
                    ["<C-Down>"] = actions.cycle_history_next,
                    ["<C-Up>"] = actions.cycle_history_prev,
                    ["<C-h>"] = actions.preview_scrolling_left,
                    ["<C-l>"] = actions.preview_scrolling_right,
                    ["<C-c>"] = actions.complete_tag,
                    ["<M-h>"] = actions.results_scrolling_left,
                    ["<M-l>"] = actions.results_scrolling_right,
                    ["<M-m>"] = actions_layout.toggle_mirror,
                    ["<M-p>"] = actions_layout.toggle_prompt_position,
                    ["?"] = actions_layout.toggle_preview,
                    ["<C-r><C-w>"] = false,
                },
                n = {
                    ["<C-j>"] = actions.move_selection_next,
                    ["<C-r>"] = trouble.open,
                    ["<C-t>"] = actions.select_tab,
                    ["<C-k>"] = actions.move_selection_previous,
                    ["<M-m>"] = actions_layout.toggle_mirror,
                    ["<M-p>"] = actions_layout.toggle_prompt_position,
                    ["?"] = actions_layout.toggle_preview,
                },
            },
        },
        pickers = require("tt._plugins.telescope.pickers").pickers,
        extensions = require("tt._plugins.telescope.extensions").extensions,
    }

    local modules = { "commands", "extensions", "keymaps" }
    for _, module in ipairs(modules) do
        require("tt._plugins.telescope." .. module).setup()
    end
end

return M

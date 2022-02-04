local M = {}

function M.setup()
    -- Module that shows the current cursor context
    local gps = require "nvim-gps"

    -- Get the colors of the theme
    local colors = require("nightfox.colors").load "nordfox"

    require("lualine").setup {
        options = {
            icons_enabled = true,
            always_divide_middle = true,
            theme = "nightfox",
            component_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
        },
        sections = {
            lualine_a = {
                {
                    "mode",
                    padding = 1,
                    separator = { right = " " },
                    icon = "",
                },
            },
            lualine_b = {
                "branch",
                "diff",
                {
                    "diagnostics",
                    symbols = { error = "", hint = "", info = "", warn = "" },
                },
            },
            lualine_c = {
                {
                    gps.get_location,
                    cond = gps.is_available,
                    color = { fg = colors.magenta },
                },
            },
            lualine_x = { "encoding", "fileformat", "filetype" },
            lualine_y = { "progress" },
            lualine_z = { "location" },
        },
    }
end

return M

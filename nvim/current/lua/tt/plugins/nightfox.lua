local M = {}

function M.setup()
    local colors = require("nightfox.colors").init "nordfox"
    local util = require "nightfox.util"

    -- My custom color
    local custom_colors = {
        bg = util.brighten(colors.bg, 0.05),
        fg = util.brighten(colors.bg, 0.50),
    }

    require("nightfox").setup {
        fox = "nordfox", -- Which fox style should be applied
        transparent = false, -- Disable setting the background color
        alt_nc = false, -- Non current window bg to alt color see `hl-NormalNC`
        terminal_colors = true, -- Configure the colors used when opening :terminal
        styles = {
            comments = "italic",
            functions = "bold",
            keywords = "NONE",
            strings = "NONE",
            variables = "NONE",
        },
        inverse = {
            match_paren = false, -- Enable/Disable inverse highlighting for match parens
            visual = false, -- Enable/Disable inverse highlighting for visual selection
            search = false, -- Enable/Disable inverse highlights for search highlights
        },
        colors = { -- Override default colors
        },
        hlgroups = { -- Override highlight groups
            TelescopeBorder = {
                fg = colors.bg_alt,
                bg = colors.bg_alt,
            },
            TelescopeMatching = {
                fg = colors.magenta,
            },
            TelescopePromptBorder = {
                fg = custom_colors.bg,
                bg = custom_colors.bg,
            },
            TelescopePromptNormal = {
                fg = custom_colors.fg,
                bg = custom_colors.bg,
            },
            TelescopePromptPrefix = {
                fg = colors.magenta,
                bg = custom_colors.bg,
            },
            TelescopePromptTitle = {
                fg = colors.bg,
                bg = colors.magenta,
            },
            TelescopePreviewTitle = {
                fg = colors.bg,
                bg = colors.cyan,
            },
            TelescopePreviewNormal = {
                bg = colors.bg_alt,
            },
            TelescopeResultsTitle = {
                fg = colors.bg,
                bg = colors.magenta,
            },
            TelescopeResultsNormal = {
                bg = colors.bg_alt,
            },
            TelescopeSelectionCaret = {
                fg = colors.cyan,
                bg = colors.bg_alt,
            },
            CmpItemKindFunction = {
                fg = colors.magenta,
            },
            CmpItemKindMethod = {
                fg = colors.magenta,
            },
        },
    }

    -- Load the configuration set above and apply the colorscheme
    require("nightfox").load()
end

return M

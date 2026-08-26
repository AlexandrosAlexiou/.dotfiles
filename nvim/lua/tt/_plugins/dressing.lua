local M = {}

function M.setup()
    require("dressing").setup {
        -- Leave vim.ui.select to snacks.picker, which is themed through the
        -- SnacksPicker* groups. Dressing loads after snacks has installed its
        -- implementation, so disabling this falls through to it instead of the
        -- telescope backend, whose highlights are only set up for nordfox.
        select = {
            enabled = false,
        },

        input = {
            -- Where to align the prompt, can be 'left', 'right', 'center'
            prompt_align = "center",

            -- Highlights: 'NormalFloat' for the text, 'FloatBorder' for the border
            win_options = {
                winhighlight = "FloatBorder:DressingBorder",
            },

            -- Make ui.input centered by default
            relative = "editor",
        },
    }
end

return M

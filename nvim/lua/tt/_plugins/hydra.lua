local M = {}

local Hydra = require "hydra"

local function setup_window_management_hydra()
    local hint = [[
^  ^^^^^^              ^^^^^^ ^ ^^^^ ^          ^^^ ^ ^ ^                ^
^  ^^^^^^     Move     ^^^^^^ ^ ^^^^  Resize   ^^^^ ^ ^     Split     ^  ^
^  ^^^^^^--------------^^^^^^ ^ ^^^^-----------^^^^ ^ ^---------------^  ^
^  ^ ^ _k_ ^ ^    ^ ^ _K_ ^ ^ ^ ^   ^ ^ _+_ ^ ^   ^ ^ _s_: horizontally  ^
^  _h_ ^ ^ _l_    _H_ ^ ^ _L_ ^ ^   _<_ ^ ^ _>_   ^ ^ _v_: vertically    ^
^  ^ ^ _j_ ^ ^    ^ ^ _J_ ^ ^ ^ ^   ^ ^ _-_ ^ ^   ^ ^ _q_: close         ^
^  ^^^^^^cursor  window^^^^^^ ^ ^^^_=_: equalize^^^ ^ _o_: only          ^
]]

    Hydra {
        name = "Window Management",
        hint = hint,
        config = {
            invoke_on_body = true,
            hint = {
                float_opts = {
                    border = "rounded",
                },
                offset = -1,
            },
        },
        mode = "n",
        body = "<leader>w",
        heads = {
            -- Move cursor
            { "h", "<C-w>h" },
            { "j", "<C-w>j" },
            { "k", "<C-w>k" },
            { "l", "<C-w>l" },
            { "w", "<C-w>w", { exit = true, desc = false } },
            { "<C-w>", "<C-w>w", { exit = true, desc = false } },
            { "W", "<C-w>W", { exit = true, desc = false } },

            -- Move window
            { "H", "<C-w>H" },
            { "J", "<C-w>J" },
            { "K", "<C-w>K" },
            { "L", "<C-w>L" },

            -- Resize
            { "+", "<C-w>+" },
            { "-", "<C-w>-" },
            { "<", "<C-w><" },
            { ">", "<C-w>>" },
            { "=", "<C-w>=", { desc = "equalize" } },

            -- Split current
            { "s", "<C-w>s" },
            { "<C-s>", "<C-w><C-s>", { desc = false } },
            { "v", "<C-w>v" },
            { "<C-v>", "<C-w><C-v>", { desc = false } },
            { "x", "<C-w>s", { desc = false } },

            -- Split into tab
            { "T", "<C-w>T", { desc = false } },

            -- Close current
            { "q", "<C-w>q", { desc = "close" } },
            { "<C-q>", "<C-w>q", { desc = false } },

            -- Close others
            { "o", "<C-w>o", { exit = true, desc = "only" } },
            { "<C-o>", "<C-w>o", { exit = true, desc = false } },
        },
    }
end

function M.setup()
    setup_window_management_hydra()
end

return M

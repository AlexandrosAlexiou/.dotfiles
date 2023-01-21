--- Prints the supplied value.
---@param value any: The value to be printed.
function _G.Print(value)
    vim.pretty_print(value)
end

-- Create a wrapper for nvim-web-devicons.
---@param path string: The path for the requested icon.
---@return any
function _G.WebDevIcons(path)
    local extension = vim.fn.fnamemodify(path, ":e")
    local filename = vim.fn.fnamemodify(path, ":t")
    return require("nvim-web-devicons").get_icon(filename, extension, { default = true })
end

--- Returns whether or not neovim is running in headless mode.
---@return boolean
function _G.HeadlessMode()
    return #vim.api.nvim_list_uis() == 0
end

--- Returns whether or not neovim runs inside WSL.
---@return boolean
function _G.IsWSL()
    local output = vim.fn.systemlist "uname -r"
    return not not string.find(output[1] or "", "WSL") or string.find(output[1] or "", "Microsoft")
end
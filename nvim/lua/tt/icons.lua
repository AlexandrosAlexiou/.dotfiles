--- Defines which kind source to use
local kind_source = _G.IsWSL() and "default" or "vscode"

--- asdasdas

local kind = {
    default = {
        Class = "󰠱  ",
        Color = "󰏘  ",
        Constant = "󰏿  ",
        Constructor = "  ",
        Enum = "  ",
        EnumMember = "  ",
        Event = "  ",
        Field = "󰜢  ",
        File = "󰈙  ",
        Folder = "󰉋  ",
        Function = "󰊕  ",
        Interface = "  ",
        Keyword = "󰌋  ",
        Method = "󰆧  ",
        Module = "  ",
        Operator = "󰆕  ",
        Property = "󰜢  ",
        Reference = "󰈇  ",
        Snippet = "  ",
        Struct = "󰙅  ",
        Text = "󰉿  ",
        TypeParameter = "  ",
        Unit = "󰑭  ",
        Value = "󰎠  ",
        Variable = "󰀫  ",
    },
    -- https://github.com/hrsh7th/nvim-cmp/wiki/Menu-Appearance#how-to-add-visual-studio-code-codicons-to-the-menu
    vscode = {
        Array = "  ",
        Boolean = "  ",
        Class = "  ",
        Color = "  ",
        Constant = "  ",
        Constructor = "  ",
        Copilot = " ",
        Enum = "  ",
        EnumMember = "  ",
        Event = "  ",
        Field = "  ",
        File = "  ",
        Folder = "  ",
        Function = "  ",
        Interface = "  ",
        Keyword = "  ",
        Method = "  ",
        Module = "  ",
        Number = "  ",
        Object = "  ",
        Operator = "  ",
        Property = "  ",
        Reference = "  ",
        Snippet = "",
        String = "",
        Struct = "  ",
        Text = "  ",
        TypeParameter = "  ",
        Unit = "  ",
        Value = "  ",
        Variable = "  ",
    },
}

local kind_trimmed = (function()
    local result = {}
    for key, value in pairs(kind[kind_source]) do
        result[key] = require("tt.utils").trim(value)
    end
    return result
end)()

local dap = {
    Stopped = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
    Breakpoint = " ",
    BreakpointCondition = " ",
    BreakpointRejected = { " ", "DiagnosticError" },
    LogPoint = ".>",
}

local diagnostics = {
    Error = " ",
    Warn = " ",
    Hint = " ",
    Info = " ",
}

local git = {
    Added = " ",
    Modified = " ",
    Removed = " ",
}

local misc = {
    AlignRight = "",
    ArrowColappsed = "",
    ArrowCollapsedSmall = "",
    ArrowExpanded = "",
    ArrowExpandedSmall = "",
    ArrowRight = "➜",
    ArrowSouthWest = "󰁂",
    BigCircle = "",
    BigUnfilledCircle = "",
    Bug = "",
    BugColored = "🐞",
    Bulb = "󰌵",
    BulbColored = "💡",
    Calendar = "󰃮",
    CallIncoming = "",
    CallOutgoing = "",
    CheckMark = "✓",
    ChevronRight = "",
    Circle = "●",
    CodeInspect = "",
    Database = "󰆼",
    DoubleChevronDown = "",
    DoubleChevronUp = "",
    Edit = "",
    Ellipsis = "…",
    Ghost = "",
    GitBranch = "",
    GitCompare = "",
    Github = "",
    LeftFilledArrow = "",
    LeftHalfCircle = "",
    LeftUnfilledArrow = "",
    Neovim = "",
    Notes = " ",
    Owl = "",
    Plug = "",
    Plus = "󰐕",
    Quit = " ",
    Restore = "",
    RightFilledArrow = "",
    RightHalfCircle = "",
    RightUnfilledArrow = "",
    Search = "",
    Selection = "",
    SelectionCaret = "",
    Settings = " ",
    Sleep = "󰒲",
    Star = "*",
    TextSearch = "󰺮",
    Thunder = "⚡",
    VerticalShadowedBox = " ",
    XMark = "✗",
}

local document = {
    Document = "󰈔",
    DocumentSearch = "󰱼",
    DocumentWord = "󰈙",
    Documents = "󰈢",
    FileCog = "󱁻",
    FileEye = "󰷊",
    FileUndo = "󰣜",
    FolderClosed = "",
    FolderConfig = "",
    FolderEmpty = "󰉖",
    FolderOpen = "",
}

return {
    kind = kind[kind_source],
    breadcrumps = kind_trimmed,
    dap = dap,
    diagnostics = diagnostics,
    document = document,
    git = git,
    misc = misc,
}

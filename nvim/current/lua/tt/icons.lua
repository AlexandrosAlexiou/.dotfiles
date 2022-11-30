--- Defines which kind source to use
local kind_source = _G.IsWSL() and "default" or "vscode"

local kind = {
    default = {
        Class = "  ",
        Color = "  ",
        Constant = "  ",
        Constructor = "  ",
        Enum = "了 ",
        EnumMember = "  ",
        Event = "  ",
        Field = "  ",
        File = "  ",
        Folder = "  ",
        Function = "ƒ  ",
        Interface = "  ",
        Keyword = "  ",
        Method = "  ",
        Module = "  ",
        Operator = "  ",
        Property = "  ",
        Reference = "  ",
        Snippet = "﬌  ",
        Struct = "  ",
        Text = "  ",
        TypeParameter = "  ",
        Unit = "塞 ",
        Value = "  ",
        Variable = "  ",
    },
    -- https://github.com/hrsh7th/nvim-cmp/wiki/Menu-Appearance#how-to-add-visual-studio-code-codicons-to-the-menu
    vscode = {
        Text = "  ",
        Method = "  ",
        Function = "  ",
        Constructor = "  ",
        Field = "  ",
        Variable = "  ",
        Class = "  ",
        Interface = "  ",
        Module = "  ",
        Property = "  ",
        Unit = "  ",
        Value = "  ",
        Enum = "  ",
        Keyword = "  ",
        Snippet = "﬌  ",
        Color = "  ",
        File = "  ",
        Reference = "  ",
        Folder = "  ",
        EnumMember = "  ",
        Constant = "  ",
        Struct = "  ",
        Event = "  ",
        Operator = "  ",
        TypeParameter = "  ",
    },
}

local diagnostics = {
    Error = "",
    Hint = "",
    Info = "",
    Warn = "",
}

local misc = {
    ArrowColappsed = "",
    ArrowExpanded = "",
    ArrowRight = "➜",
    BigCircle = " ",
    BigUnfilledCircle = " ",
    Branch = "",
    Bulb = "",
    Bullets = "ﯟ",
    Calendar = "",
    CheckMark = "✓",
    ChevronRight = ">",
    Circle = " ",
    LeftFilledArrow = "",
    LeftHalfCircle = "",
    LeftUnfilledArrow = "",
    Owl = "",
    Plug = "",
    RightFilledArrow = "",
    RightHalfCircle = "",
    RightUnfilledArrow = "",
    SmallArrowCollapsed = "",
    SmallArrowExpanded = "",
    Star = "*",
    Storage = "",
    VerticalShadowedBox = " ",
    XMark = "✗",
}

local document = {
    Document = "",
    DocumentSearch = "",
    DocumentWord = "",
    DoubleDocument = "",
    FolderClosed = "",
    FolderEmpty = "ﰊ",
    FolderOpen = "",
}

local navic = {
    Array = " ",
    Boolean = "◩ ",
    Class = " ",
    Constant = " ",
    Constructor = " ",
    Enum = "練",
    EnumMember = " ",
    Event = " ",
    Field = " ",
    File = " ",
    Function = " ",
    Interface = "練",
    Key = " ",
    Method = " ",
    Module = " ",
    Namespace = " ",
    Null = "ﳠ ",
    Number = " ",
    Object = " ",
    Operator = " ",
    Package = " ",
    Property = " ",
    String = " ",
    Struct = " ",
    TypeParameter = " ",
    Variable = " ",
}

local barbecue = {
    Array = "",
    Boolean = "蘒",
    Class = "",
    Color = "",
    Constant = "",
    Constructor = "",
    Enum = "",
    EnumMember = "",
    Event = "",
    Field = "",
    File = "",
    Folder = "",
    Function = "",
    Interface = "",
    Key = " ",
    Keyword = "",
    Method = "",
    Module = "",
    Namespace = "",
    Null = "ﳠ",
    Number = "",
    Object = "",
    Operator = "",
    Package = "",
    Property = "",
    Reference = "",
    Snippet = "",
    String = "",
    Struct = "",
    Text = "",
    TypeParameter = "",
    Unit = "",
    Value = "",
    Variable = "",
}

return {
    kind = kind[kind_source],
    diagnostics = diagnostics,
    document = document,
    misc = misc,
    navic = navic,
    barbecue = barbecue,
}

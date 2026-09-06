local Actions = require "snacks.explorer.actions"
local Tree = require "snacks.explorer.tree"
local Watch = require "snacks.explorer.watch"

local uv = vim.uv or vim.loop

local M = {}

---Generation token: bumping it cancels any in-flight recursive operation,
---e.g. when a new one starts or the picker closes.
local generation = 0

---Minimum delay between progressive list refreshes while expanding
local update_interval_ns = 400 * 1e6

--[[
Override of Watch.watch(): the upstream version runs on *every* finder pass
and synchronously starts/stops one `uv_fs_event` handle per open directory.
On macOS each handle is an FSEventStream, which is expensive to create and
destroy: after a recursive expand this meant thousands of streams, and a
recursive collapse then destroyed all of them in one blocking loop, freezing
the UI.

macOS supports `recursive = true` fs events (FSEvents), so a *single* watcher
on the explorer root covers the entire subtree: full auto-refresh coverage
with zero per-directory handles and zero watcher churn on recursive
expand/collapse. Events are recorded in a fast (luv) context and drained on
the main loop, throttled to one refresh per 100ms.

NOTE: this relies on FSEvents, i.e. it is macOS-only. Linux (inotify) has no
recursive mode and would need upstream's per-directory watchers instead, see:
- https://www.man7.org/linux/man-pages/man7/inotify.7.html (Limitations and caveats:
  "Inotify monitoring of directories is not recursive")
- https://docs.libuv.org/en/v1.x/fs_event.html (UV_FS_EVENT_RECURSIVE is
  "supported by some backends", i.e. FSEvents/ReadDirectoryChangesW only)
--]]
do
    local scheduled = false

    local recursive = {} ---@type table<string, boolean> cwds covered by a recursive watcher
    local pending = {} ---@type table<string, boolean> paths touched by fs events
    local has_pending = false
    local debounce = assert(uv.new_timer())

    ---Drains the recorded fs events on the main loop: refreshes the affected
    ---directories and triggers the upstream (debounced) picker update
    local function drain()
        if not has_pending then
            return
        end
        has_pending = false
        local paths = vim.tbl_keys(pending) ---@type string[]
        pending = {}
        for _, path in ipairs(paths) do
            Tree:refresh(path)
        end
        Watch.refresh()
    end

    ---Starts a single recursive watcher covering the whole tree under `cwd`
    ---@param cwd string
    local function start_recursive(cwd)
        if recursive[cwd] and Watch._watches[cwd] then
            return
        end
        if Watch._watches[cwd] then
            Watch.stop(cwd) -- replace a legacy non-recursive watcher
        end
        local handle = assert(uv.new_fs_event())
        local ok, err = handle:start(cwd, { recursive = true }, function(werr, file)
            if werr then
                return
            end
            -- Fast (luv) context: only record the event here
            local path = not file and cwd or (file:sub(1, 1) == "/" and file or cwd .. "/" .. file)
            pending[path] = true
            has_pending = true
            if not debounce:is_active() then
                debounce:start(100, 0, vim.schedule_wrap(drain))
            end
        end)
        if not ok then
            if not handle:is_closing() then
                handle:close()
            end
            Snacks.notify.error("Failed to watch " .. cwd .. ": " .. err)
            return
        end
        recursive[cwd] = true
        Watch._watches[cwd] = handle
    end

    function Watch.watch()
        if scheduled then
            return
        end
        scheduled = true

        vim.defer_fn(function()
            scheduled = false

            local used = {} ---@type table<string, boolean>
            local pickers = Snacks.picker.get { source = "explorer", tab = false }
            for _, picker in ipairs(pickers) do
                local cwd = picker:cwd()
                if not used[cwd] then
                    used[cwd] = true
                    start_recursive(cwd)

                    -- Watch the git index
                    local root = Snacks.git.get_root(cwd)
                    if root then
                        local git_dir = root .. "/.git"
                        if not used[git_dir] then
                            used[git_dir] = true
                            if not Watch._watches[git_dir] then
                                Watch.start(git_dir, function(file)
                                    if vim.fs.basename(file) == "index" then
                                        require("snacks.explorer.git").refresh(root)
                                        Watch.refresh()
                                    end
                                end)
                            end
                        end
                    end
                end
            end

            -- Stop stale watchers (closed pickers or a changed cwd)
            for path in pairs(Watch._watches) do
                if not used[path] then
                    recursive[path] = nil
                    Watch.stop(path)
                end
            end
        end, 20)
    end
end

---Creates a throttled list updater for the given picker.
---The first progressive update fires only after `update_interval_ns`, so
---small expands that finish quickly trigger a single (forced) refresh
---instead of two back-to-back finder runs.
---@param picker snacks.Picker
local function make_updater(picker)
    local last = uv.hrtime()
    ---@param force? boolean
    return function(force)
        local now = uv.hrtime()
        if force or (now - last) > update_interval_ns then
            last = now
            Actions.update(picker, { refresh = true })
        end
    end
end

---Recursively expands the given node without blocking the UI.
---Directory listing runs asynchronously on libuv's threadpool (off the main
---thread, up to `max_inflight` concurrent scans), while tree mutations are
---applied on the main loop, one directory at a time.
---@param picker snacks.Picker
---@param root snacks.picker.explorer.Node
---@param gen number
local function expand_async(picker, root, gen)
    local queue = {} ---@type snacks.picker.explorer.Node[]
    local qhead, qtail = 1, 0
    local inflight, max_inflight = 0, 50
    local seen = {} ---@type table<string, boolean> guards against symlink cycles
    local update = make_updater(picker)

    local scan

    local function cancelled()
        return gen ~= generation or picker.closed
    end

    local function drain()
        if cancelled() then
            return
        end
        while inflight < max_inflight and qhead <= qtail do
            local node = queue[qhead]
            queue[qhead] = nil
            qhead = qhead + 1
            scan(node)
        end
        if inflight == 0 and qhead > qtail then
            update(true)
        end
    end

    ---@param node snacks.picker.explorer.Node
    local function enqueue(node)
        if node.dir and not seen[node.path] then
            seen[node.path] = true
            qtail = qtail + 1
            queue[qtail] = node
        end
    end

    ---Applies the scandir results to the tree, runs on the main loop.
    ---Mirrors the logic of Tree:expand(), minus the blocking scandir.
    ---@param node snacks.picker.explorer.Node
    ---@param entries? { [1]: string, [2]: string? }[]
    local function apply(node, entries)
        inflight = inflight - 1
        if cancelled() then
            return
        end
        if entries then
            local found = {} ---@type table<string, boolean>
            for _, entry in ipairs(entries) do
                local name = entry[1]
                local t = entry[2] or Snacks.util.path_type(node.path .. "/" .. name)
                found[name] = true
                local child = Tree:child(node, name, t)
                child.type = t
                child.dir = t == "directory" or (t == "link" and vim.fn.isdirectory(child.path) == 1)
            end
            for name in pairs(node.children) do
                if not found[name] then
                    node.children[name] = nil
                end
            end
            node.expanded = true
            node.utime = uv.hrtime()
        end
        -- Only mark the node open once it is fully scanned, so intermediate
        -- list refreshes never fall back to a synchronous Tree:expand()
        node.open = true
        for _, child in pairs(node.children) do
            enqueue(child)
        end
        update()
        drain()
    end

    ---@param node snacks.picker.explorer.Node
    scan = function(node)
        inflight = inflight + 1
        if node.expanded then
            -- Already scanned: reuse the cached children without touching the fs
            vim.schedule(function()
                apply(node)
            end)
            return
        end
        uv.fs_scandir(node.path, function(err, fs)
            -- Fast (luv) context: only collect the raw entries here
            local entries = {} ---@type { [1]: string, [2]: string? }[]
            while not err and fs do
                local name, t = uv.fs_scandir_next(fs)
                if not name then
                    break
                end
                entries[#entries + 1] = { name, t }
            end
            vim.schedule(function()
                apply(node, entries)
            end)
        end)
    end

    enqueue(root)
    drain()
end

---Recursively collapses the given node in deferred batches.
---This is pure in-memory work (no syscalls, no path lookups), so batches
---can be large while each tick stays in the sub-millisecond range.
---@param picker snacks.Picker
---@param root snacks.picker.explorer.Node
---@param gen number
local function collapse_async(picker, root, gen)
    local stack = { root }
    local top = 1
    local batch = 2000

    local function step()
        if gen ~= generation or picker.closed then
            return
        end
        local count = 0
        while top > 0 and count < batch do
            local node = stack[top]
            stack[top] = nil
            top = top - 1
            node.open = false
            node.expanded = false -- clear expanded state, same as Tree:close()
            for _, child in pairs(node.children) do
                if child.dir then
                    top = top + 1
                    stack[top] = child
                end
            end
            count = count + 1
        end

        if top > 0 then
            vim.defer_fn(step, 0)
            return
        end

        Actions.update(picker, { refresh = true })
    end

    -- The first batch runs synchronously: collapsing is memory-only work,
    -- so small trees finish instantly without a deferred round-trip
    step()
end

---Source code adapted from: https://github.com/folke/snacks.nvim/discussions/1306#discussioncomment-12248922
---@type snacks.picker.Config
M.explorer = {
    hidden = true, -- Show hidden files (dotfiles) by default
    ignored = true, -- Also show gitignored files (e.g. .claude/, .sakuin/)
    layout = {
        preview = "main",
        layout = {
            backdrop = false,
            width = 50,
            min_width = 40,
            height = 0.5, -- Vertical size: 80% of screen height (or use absolute number like 50 for 50 lines)
            position = "left",
            box = "vertical",
            { win = "input", height = 1 }, -- Search input at top
            { win = "list", border = "none" }, -- File list below input
        },
    },
    on_show = function(picker)
        local window_gap = 1

        local root = picker.layout.root

        ---@param win snacks.win
        local update = function(win)
            -- Bail out if the root or target window is gone (e.g. the explorer
            -- was closed), otherwise the WinResized callback below fires against
            -- an invalid window handle and errors out.
            if not (root.win and vim.api.nvim_win_is_valid(root.win)) then
                return
            end
            if not (win and win:win_valid()) then
                return
            end
            win.opts.row = vim.api.nvim_win_get_position(root.win)[1]
            win.opts.col = vim.api.nvim_win_get_width(root.win) + window_gap
            win.opts.height = 0.85
            win.opts.width = 0.5
            win:update()
        end

        local preview_win = Snacks.win.new {
            relative = "editor",
            external = false,
            focusable = false,
            border = "rounded",
            backdrop = false,
            show = false,
            bo = {
                filetype = "snacks_float_preview",
                buftype = "nofile",
                buflisted = false,
                swapfile = false,
                undofile = false,
            },
            on_win = function(win)
                update(win)
                picker:show_preview()
            end,
        }

        picker.preview.win = preview_win

        root:on("WinResized", function()
            update(preview_win)
        end)
    end,
    actions = {
        toggle_preview = function(picker)
            picker.preview.win:toggle()
        end,
        scroll_down = function(picker)
            if picker.list and picker.list.win and picker.list.win.win then
                picker:action "list_down"
            end
        end,
        scroll_up = function(picker)
            if picker.list and picker.list.win and picker.list.win.win then
                picker:action "list_up"
            end
        end,
        expand_recursive = function(picker, item)
            local node = item and Tree:node(item.file)
            if not node or not node.dir then
                return
            end

            generation = generation + 1
            expand_async(picker, node, generation)
        end,
        collapse_recursive = function(picker, item)
            local node = item and Tree:node(item.file)
            if not node or not node.dir then
                return
            end

            generation = generation + 1
            collapse_async(picker, node, generation)
        end,
    },
    win = {
        list = {
            keys = {
                ["-"] = "explorer_up",
                ["o"] = "confirm",
                ["="] = "confirm",
                ["+"] = "confirm",
                ["O"] = "explorer_open",
                ["?"] = "toggle_help_list",
                ["L"] = "expand_recursive",
                ["H"] = "collapse_recursive",
                ["<C-t>"] = "tab",
                ["<C-f>"] = "focus_input",
                ["<M-h>"] = false,
                ["<C-u>"] = "scroll_up", -- Scroll up with Ctrl+u
                ["<C-d>"] = "scroll_down", -- Scroll down with Ctrl+d
            },
        },
    },
}

return M

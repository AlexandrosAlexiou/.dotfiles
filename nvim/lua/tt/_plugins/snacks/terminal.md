# Terminal Management System

Built on top of [Snacks.nvim](https://github.com/folke/snacks.nvim) terminals.

## Keybindings

### Create

| Key            | Action                              |
| -------------- | ----------------------------------- |
| `<leader>ht`   | New horizontal (bottom) terminal    |
| `<leader>vt`   | New vertical (right) terminal       |
| `<leader>ft`   | Toggle floating full-screen terminal|
| `<leader>bt`   | Toggle btop in a float              |

### Toggle

| Key            | Action                                        |
| -------------- | --------------------------------------------- |
| `<leader>tt`   | Toggle the last active split terminal          |
| `<leader>\``   | Toggle **all** split terminals at once         |

### Inside a terminal

| Key            | Action                        |
| -------------- | ----------------------------- |
| `<C-/>`        | Hide the current terminal     |
| `<C-h/j/k/l>` | Navigate to neighbouring window|
| `<Esc>`        | Exit terminal mode            |

## How it works

- **`ht` / `vt`** always create a new terminal. Each new split takes 50% of the current window.
- Terminals are **auto-equalized** via a tree-based algorithm that walks `vim.fn.winlayout()` — widths and heights are distributed proportionally so every terminal gets equal space.
- Manual resizes are **persisted** — drag a border and the system saves a full proportional tree snapshot of the layout. Hide/show restores the exact same proportions, including complex nesting (verticals inside horizontals, etc.).
- **`<leader>\``** hides all terminals; pressing it again restores them in creation order with the saved proportions.
- Terminals are **explorer-aware** — opening the explorer (`<leader>fe`) re-equalizes terminals to share space. Closing it gives the space back.
- `winfixwidth` / `winfixheight` are kept **locked** on terminal windows so Vim's layout engine never touches them when panels open or close. Only the equalize pass resizes terminals (one SIGWINCH per terminal, no prompt flicker).
- `lazyredraw` is held across layout transitions so the screen paints a single clean frame.

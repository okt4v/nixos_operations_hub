# Neovim Config Overview

Leader key = `Space`

---

## Navigation

| Key | Action |
|-----|--------|
| `<C-h/j/k/l>` | Move between splits |
| `<S-h>` / `<S-l>` | Previous / next buffer |
| `s` + 2 chars | Flash jump to any visible position |
| `S` | Flash select treesitter node |
| `<leader>e` | File explorer (netrw) |
| `<leader>1–4` | Jump to harpoon pinned file |
| `<leader>a` | Pin current file to harpoon |
| `<leader>A` | Open harpoon menu |

---

## Finding Things (fzf-lua)

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep across project |
| `<leader>fb` | Open buffers |
| `<leader>fr` | Recent files |
| `<leader>fs` | LSP symbols in file |
| `<leader>fw` | LSP symbols in workspace |
| `<leader>fd` | Diagnostics in file |
| `<leader>ft` | Search TODO/FIXME/HACK comments |
| `<leader>th` | Pick colour theme |

---

## LSP

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gI` | Go to implementation |
| `gr` | References |
| `K` | Hover documentation |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `<leader>d` | Diagnostic float |
| `<leader>dj` / `<leader>dk` | Next / prev diagnostic |

---

## Editing

| Key | Action |
|-----|--------|
| `gc` / `gcc` | Comment selection / line |
| `ys<motion><char>` | Add surround (`ysiw"` surrounds word with `"`) |
| `cs<old><new>` | Change surround (`cs"'` changes `"` to `'`) |
| `ds<char>` | Delete surround (`ds"` removes `"`) |
| `<A-j>` / `<A-k>` | Move line or selection up / down |
| `<` / `>` | Indent / dedent and stay in visual mode |
| `<leader>cf` | Format buffer manually |
| `<Esc>` | Clear search highlight |

---

## Completion

| Key | Action |
|-----|--------|
| `<Tab>` / `<S-Tab>` | Next / prev suggestion |
| `<Down>` / `<Up>` | Next / prev suggestion |
| `<S-Enter>` | Accept suggestion |
| `<C-Space>` | Open completion manually |
| `<C-e>` | Dismiss completion |
| `<C-b>` / `<C-f>` | Scroll docs up / down |

---

## Yank History (yanky)

| Key | Action |
|-----|--------|
| `p` / `P` | Paste after / before (tracked in history) |
| `<C-p>` / `<C-n>` | Cycle through previous yanks after pasting |

---

## Git

| Key | Action |
|-----|--------|
| `<leader>hj` / `<leader>hk` | Next / prev hunk |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | Blame line (full) |
| `<leader>hd` | Diff this file |
| `<leader>gd` | Open full diff view (branch) |
| `<leader>gh` | File git history with diffs |
| `<leader>gq` | Close diff view |

---

## Refactoring (Python, C++ — visual select first)

| Key | Action |
|-----|--------|
| `<leader>rs` | Pick from available refactors |
| `<leader>rf` | Extract selection into function |
| `<leader>rv` | Extract selection into variable |
| `<leader>ri` | Inline variable back into usages |

---

## Testing (Python, Go)

| Key | Action |
|-----|--------|
| `<leader>tn` | Run nearest test |
| `<leader>tf` | Run all tests in file |
| `<leader>ts` | Toggle test summary panel |
| `<leader>to` | Toggle test output panel |
| `<leader>tx` | Stop running test |

---

## Jupyter / Notebooks (molten)

| Key | Action |
|-----|--------|
| `<leader>mi` | Initialise kernel |
| `<leader>ml` | Evaluate current line |
| `<leader>mr` | Re-evaluate cell |
| `<leader>mo` / `<leader>mh` | Show / hide output |
| `<leader>md` | Delete cell |
| `<leader>mv` | Evaluate visual selection |

---

## Session & UI

| Key | Action |
|-----|--------|
| `<leader>qs` | Restore session for current directory |
| `<leader>ql` | Restore last session (any directory) |
| `<leader>qd` | Don't save session on exit |
| `<leader>z` | Toggle zen mode |

---

## LaTeX (vimtex — inside a .tex file)

| Key | Action |
|-----|--------|
| `\ll` | Start / stop compilation |
| `\lv` | Forward search in Zathura |
| `\le` | Show errors |
| `\lc` | Clean auxiliary files |

---

## Auto-behaviours (no keybind needed)

- **Autopairs** — `(` → `()`, `"` → `""`, etc.
- **Format on save** — ruff (Python), clang-format (C/C++), stylua (Lua), prettier (JSON/YAML), shfmt (Bash), nixfmt (Nix)
- **Indent detection** — vim-sleuth reads the file and sets tab/space width automatically
- **Indent guides** — faint `│` lines show indentation levels
- **Git signs** — `│` / `_` / `~` in the gutter for added / deleted / changed lines
- **Colour preview** — hex codes like `#ff8c00` are shown with their actual colour as background
- **TODO highlighting** — `TODO`, `FIXME`, `HACK`, `NOTE` are highlighted in comments
- **Cross-file completions** — Python (pyright) works automatically; C++ needs `compile_commands.json` in project root (run `bear -- make` or enable in CMake)

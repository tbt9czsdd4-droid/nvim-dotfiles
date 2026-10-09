# Neovim config

A hybrid editor/IDE setup for Neovim 0.12+, with plugins managed by `vim.pack`.
The leader key is Space.

## Installation

Requires Neovim **0.12 or newer** (checked against 0.12.5), Git, and ripgrep
(14+ for replacement, 15+ recommended). `fd` speeds up file search. The terminal
supplies the Nerd Font, including over SSH.

The theme is mini.hues with Neovim's default colors: transparent locally, opaque
over SSH. `:colorscheme cyberdream` still works.

The first launch installs the locked plugins. **Update plugins** on the dashboard
runs `vim.pack.update()`; installed Treesitter parsers update along with it.

Language servers, formatters, and parsers are installed explicitly; nothing is
provisioned on startup. A supported language server starts when its executable is
on `PATH`. Mason's bin directory comes first, so Mason, system, and rustup installs
all work, and `:MasonInstall` starts a server without a restart. Mason packages may
need Node/npm or Python (`:checkhealth mason`).

Parsers need a C compiler, `curl`, `tar`, and Tree-sitter CLI 0.26.1+ (from the
system package manager or Cargo, not npm). After `:TSInstall` for an already open
file, reopen it with `:edit`.

| Work | Servers / formatters | Parsers |
| --- | --- | --- |
| Config/Lua | `:MasonInstall lua-language-server stylua` | `:TSInstall lua luadoc vim vimdoc query` |
| Shell | `:MasonInstall bash-language-server shfmt` | `:TSInstall bash` |
| C/C++ | `:MasonInstall clangd clang-format` | `:TSInstall c cpp` |
| Python | `:MasonInstall pyright ruff` | `:TSInstall python` |
| Rust | `:MasonInstall rust-analyzer` | `:TSInstall rust` |
| Web | `:MasonInstall vtsls angular-language-server prettier` | `:TSInstall javascript jsdoc typescript tsx html angular css scss` |
| Data/Markdown | `:MasonInstall json-lsp yaml-language-server taplo markdown-oxide prettier` | `:TSInstall json yaml toml markdown markdown_inline` |
| Build/containers | `:MasonInstall neocmakelsp dockerfile-language-server docker-compose-language-service` | `:TSInstall cmake dockerfile yaml` |
| TeX/Typst/HDL | `:MasonInstall texlab tinymist` | `:TSInstall latex bibtex typst vhdl` |

Formatting uses conform: Prettier (project-local first, then `PATH`) for web, data,
and Markdown files; rustfmt from the Rust toolchain; `vsg` for VHDL (installed
separately). Rust is checked with Clippy.

## Workspaces

`nvim path/to/folder` opens that folder as a workspace and restores its files,
window layout, and buffer tab order. Any folder works; Git branches do not affect
the session, and symlinks share the real folder's workspace. An empty workspace
opens a file picker.

`nvim` opens the dashboard: **Sessions**, **Open folder**, **Recent files**,
**Config**, **Update plugins**, **Quit**. `o`/`O` opens the folder dialog: Tab
completes paths, Up/Down or Ctrl-J/Ctrl-K move through suggestions, Enter opens,
Esc cancels. Relative paths and `~` work.

File arguments, several arguments, stdin, `/` and the home folder start
standalone, without a session. Dashboard **Recent files** opens a standalone file.
Switching folders or returning to the dashboard offers **Save all / Discard /
Cancel** when buffers are modified. A snapshot that fails to restore is reported
and never overwritten.

Search, Git views, and terminals use the workspace folder, even for files outside
it; standalone they use the file's folder, then cwd. Lualine shows the workspace
name or **Standalone**.

| Shortcut | Action |
| --- | --- |
| `<leader>fp`, `<leader>qS` | All folders; `<C-d>` forgets a folder and its snapshot |
| `<leader>ql` | Open the most recent folder |
| `<leader>qs` | Open/restore the current directory as a workspace |
| `<leader>qx`, `<leader>qX` | Save and open the dashboard / restart Neovim into it (reloads config and theme) |
| `<leader>qd`, `<leader>qD` | Stop saving / delete the current snapshot |

Snapshots live in `stdpath('state')/sessions/`, folder history in
`stdpath('state')/recent-folders.json`.

## Copy and paste

Only yanking copies. `d`, `D`, `c`, `C`, `x`, `X` and `Del` delete without
touching the clipboard, and pasting over a selection keeps it. Yanks flash briefly
and leave the cursor where it was.

Over SSH, yanks reach your local clipboard through OSC 52, and `p` pastes the last
yank from this Neovim. Paste text copied on your machine with the terminal's paste
(usually Ctrl-Shift-V).

## Keys

Pressing `<leader>`, `[`, `]`, `g`, `z`, `<C-w>`, `'`, `` ` ``, `"` or `<C-r>` and
pausing shows the available follow-up keys.

**Buffers and windows**

| Shortcut | Action |
| --- | --- |
| `<S-h>`, `<S-l>` (`[b`, `]b`) | Previous / next buffer |
| `<M-H>`, `<M-L>` (`[B`, `]B`) | Move buffer tab left / right (Alt+Shift+h/l) |
| `<leader>bb`, `<leader>bj` | Other buffer / pick buffer |
| `<leader>bd`, `<leader>bo` | Delete buffer (keeps splits) / delete other buffers |
| `<leader>bp`, `<leader>bP` | Pin buffer / delete unpinned buffers |
| `<leader>bl`, `<leader>br` | Delete buffers to the left / right |
| `<C-h/j/k/l>`, `<C-arrows>` | Move between / resize windows |
| `<leader>e` | File explorer (mini.files) |
| `<leader>ft`, `<leader>fT` | Terminal in workspace / cwd |

**Search**

| Shortcut | Action |
| --- | --- |
| `<leader><space>`, `<leader>ff`, `<leader>fF` | Smart search / files (workspace) / files (cwd) |
| `<leader>fr`, `<leader>fR`, `<leader>fc`, `<leader>fg` | Recent (workspace) / recent (all) / config / Git files |
| `<leader>/`, `<leader>sg`, `<leader>sG` | Grep workspace / grep cwd |
| `<leader>sw`, `<leader>st` | Grep word or selection / TODO, FIXME, HACK, NOTE |
| `<leader>sB`, `<leader>sb` | Grep open buffers (including unsaved text) / current buffer |
| `<leader>sr` | Search and replace in the workspace |
| `<leader>sR` | Resume the last picker |
| `<leader>sd`, `<leader>sD`, `<leader>ss`, `<leader>sS` | Diagnostics / buffer diagnostics / symbols / workspace symbols |
| `<leader>sk`, `<leader>sh`, `<leader>su`, `<leader>s"` | Keymaps / help / undo history / registers |

File search and grep include hidden files, respect ignore rules, and skip `.git`.
Buffer grep skips files over 5 MiB.

**Code and Git**

| Shortcut | Action |
| --- | --- |
| `gd`, `grr`, `gI`, `gy`, `gD`, `K` | Definition / references / implementation / type / declaration / hover |
| `<leader>ca`, `<leader>cr`, `<leader>cf` | Code action / rename / format |
| `<leader>cd`, `[d`, `]d` | Line diagnostics / previous / next |
| `<leader>gs`, `<leader>gd` | Git status / diff (workspace) |
| `<leader>gl`, `<leader>gf` | Repository / current-file history |
| `[h`, `]h`, `gh`, `gH` | Previous / next hunk; stage / reset a motion (`ghgh`, `gHgh` for a hunk) |
| `<leader>uf`, `<leader>uF` | Toggle global / buffer autoformat (off by default; `:unlet b:autoformat` restores the global) |
| `<leader>ud`, `<leader>uh` | Toggle diff overlay / inlay hints |

**Editing**

| Shortcut | Action |
| --- | --- |
| `gsa`, `gsd`, `gsr` | Add / delete / replace surrounding (`gsaiw"`, `gsr"'`) |
| `gsf`, `gsF`, `gsh` | Find surrounding forward / backward / highlight |
| `cia`, `cif`; `aN`/`iN`, `aL`/`iL` | Argument and function-call text objects; next / previous object |
| `s`, `S`, `<C-Space>` | Flash jump / Treesitter jump / incremental selection |
| `<M-h/j/k/l>` | Move line or selection |
| `<Tab>` | Snippet jump, otherwise tab out of brackets |

TODO/FIXME/HACK/NOTE and hex colors are highlighted. Folding is disabled.
Renaming files in mini.files tells supporting language servers, so imports can
update.

## Search and replace

`<leader>sr` opens grug-far beside the file (below on narrow terminals), with the
workspace folder as path; in visual mode the selection becomes the search. Edit
the search and replacement, press `Esc`, then:

- `<leader>r` replaces all results;
- `<leader>n` replaces the current result line and moves to the next;
- `<leader>R` plus the letter from the help header runs the other commands
  (`<leader>Rc` closes, `<leader>Rq` sends results to quickfix); `g?` lists them.

Replacement edits files on disk and refuses files with unsaved changes in a
buffer; save or discard them first. Its windows are not saved in sessions.

## Validation

Run from this directory (installed plugins required; the refinement suite also
uses the TypeScript parser and Git):

```sh
nvim --headless -u NONE -i NONE -l tests/workspaces.lua
nvim --headless -u NONE -i NONE -l tests/startup.lua
nvim --headless -u NONE -i NONE -l tests/refinements.lua
nvim --headless -u NONE -i NONE -l tests/ui.lua
```

The suites use temporary state and files, so your sessions are never touched. The
UI suite attaches real wide and narrow UIs, simulates SSH and a fresh host, and
prints where its screen captures are.

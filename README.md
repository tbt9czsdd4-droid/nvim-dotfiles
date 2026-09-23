# Neovim folder workspaces

Open a folder with `nvim path/to/folder` to activate that exact folder and restore
its files and window layout. Any folder works; Git branches and project markers
do not affect session identity. Symlinks share the canonical folder's workspace.
An empty workspace opens a file picker, and closing every file saves an empty
session so old files do not return.

`nvim` opens the dashboard. File arguments, multiple arguments, and stdin start
standalone, without automatic session loading or saving. `/` and your home folder
also stay standalone. Search and project terminals use the active workspace folder,
even for files outside it. Standalone search uses the current file's directory,
then cwd. Language servers keep their own root detection.

The dashboard has six actions: **Sessions**, **Open folder**, **Recent files**,
**Config**, **Update plugins**, and **Quit**. Sessions lists previously opened
folders. Press `o` or `O` on the dashboard for a floating **Open folder** dialog,
prefilled with the current directory. Tab completes directory paths, including
names with spaces. Up/Down or Ctrl-K/Ctrl-J move through completion suggestions;
when completion is closed, they browse input history. Enter accepts an active
completion; otherwise it opens the folder. Escape dismisses completion first,
then cancels the dialog. Absolute
paths, relative paths, and `~` are supported. Empty input cancels; nonexistent
folders and ordinary files are rejected without switching workspaces.
You can also use `nvim path/to/folder`, or `:cd path/to/folder` followed by
`<leader>qs`. Dashboard Recent files opens a standalone file and changes cwd to
its parent. File pickers used inside the editor add files to the current
workspace. Mini.files (`<leader>e`) is the explorer; browsing does not switch
workspaces. The former Snacks Explorer shortcut (`<leader>E`) has been removed.

Folder switches and returning to the dashboard offer **Save all / Discard /
Cancel** when buffers are modified, with Cancel selected by default. Save all
prompts for unnamed files; a cancelled prompt, failed write, or remaining modified
buffer stops the transition. The outgoing session is saved before buffers are
replaced. Restore errors are reported and disable automatic saving to protect the
snapshot.

| Shortcut | Action |
| --- | --- |
| `<leader>fp`, `<leader>qS` | All folders; `<C-d>` confirms forgetting a folder and its snapshots |
| `<leader>ql` | Open the most recent existing folder |
| `<leader>qs` | Explicitly open/restore the current directory |
| `<leader>qx`, `<leader>qX` | Save workspace and open dashboard / restart |
| `<leader>qd`, `<leader>qD` | Detach / delete current snapshots (history is retained) |
| `<leader><space>`, `<leader>ff` | Workspace smart search / plain file search |
| `<leader>/`, `<leader>sB` | Workspace grep / search open buffers, including unsaved text |
| `<leader>sR` | Resume the last picker |
| `<leader>ft` | Workspace terminal |
| `<leader>bd` | Delete buffer while preserving splits |
| `<leader>uf`, `<leader>uF` | Toggle global / buffer autoformat |

The leader key is Space. Autoformat defaults off; a buffer override takes
precedence over the global default. `:unlet b:autoformat` restores inheritance.
Lualine shows the active folder or **Standalone**. Encoding and line-ending
labels appear only when different from UTF-8 and Unix; the current theme, layout,
progress, and per-buffer diagnostic badges are retained.

History lives in `stdpath('state')/recent-folders.json`, separately from
`sessions/*.vim`. Existing snapshots seed history once. On the first open of each
folder, the newest legacy snapshot (including branch variants) becomes its single
session, with original copies preserved in `sessions/legacy/`. Later opens ignore
legacy variants. Missing folders remain available for removal in **All folders…**.
Snapshot deletion also removes legacy backups, but keeps folder history; forgetting
removes both. Deleting an active snapshot detaches it until explicitly reopened.

Use **Update plugins** for `vim.pack.update()`. Installed Treesitter parsers update
along with the Treesitter plugin. Mini.files, animations, the experimental
command/message UI, and Tab/tabout behavior are retained. The UI's existing
fallback to the ordinary command line remains available when initialization fails.

## Installation on another machine

Use Neovim **0.12 or newer** (this config is checked against 0.12.5), Git, and
ripgrep (14+ for replacement; 15+ recommended). `fd` improves file discovery.
Your terminal supplies the Nerd Font, including when using SSH.

The first launch installs the locked plugins. **Language servers, formatters, and
parsers are installed explicitly**, with no automatic language provisioning on
startup. Already installed tools continue working. A server is enabled when it
is installed through Mason and belongs to this config's supported server list.

Use `:Mason` to browse tools or `:MasonInstall` with package names. The optional
`:MasonToolsInstall` batch installs clang-format, Ruff, shfmt, StyLua, and Prettier.
Mason packages may require system runtimes such as Node/npm or Python; consult
`:checkhealth mason` for that host. Rustfmt comes from the Rust toolchain.

Parser compilation needs a C compiler, `curl`, `tar`, and Tree-sitter CLI 0.26.1+
(installed through the system package manager or Cargo, not npm). Use `:TSInstall`
with the parser names below. Installed parsers are picked up by normal buffers;
after installing a parser for an already open file, reopen that file with `:edit`.

| Work | Explicit server/formatter installation | Parser installation |
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

Prettier is optional for JS/JSX, TS/TSX, HTML, CSS/SCSS, JSON/JSONC, YAML, and
Markdown. Conform prefers a project-local Prettier executable and otherwise uses
one on PATH (including Mason). Existing formatting toggles still apply, with
autoformat off by default. Rust retains Clippy checking with the project's default
features. VHDL formatting requires a separately installed `vsg`.

## Editing improvements

| Shortcut | Action / example |
| --- | --- |
| `gsa`, `gsd`, `gsr` | Add/delete/replace surrounding: `gsaiw"` quotes a word; `gsr"'` changes double quotes to single quotes |
| `gsf`, `gsF`, `gsh` | Find surrounding forward/backward or highlight it |
| `cia`, `cif` | Change an argument or the inside of a function call |
| `aN` / `iN`, `aL` / `iL` | Around/inside next or previous text object; native lowercase mappings stay available |
| `<leader>sr` | Search and replace in the workspace; visual mode prefills the selected text |
| `<leader>gs`, `<leader>gd` | Workspace Git status / diff |
| `<leader>gl`, `<leader>gf` | Repository history / current-file history |
| `[h`, `]h` | Previous / next diff hunk |
| `gh`, `gH` | Stage / reset a motion or visual region |
| `ghgh`, `gHgh` | Stage / reset the current hunk |

Git reset (`gH`) restores buffer text from the Git index, discarding those unstaged
edits; ordinary undo can restore that buffer change. Git status also exposes the
picker's own stage/restore actions. File history follows the current file even
outside the active workspace.

Files stay fully visible: automatic folding is disabled, including after restoring
older sessions. Treesitter syntax highlighting remains enabled. Native Vim folding
commands remain available if you deliberately enable manual folding.

Surround and text objects reuse Mini; Flash keeps `s` and incremental selection.
Delete/change still preserve the last yank. As before, these mappings also
prevent explicit-register cuts such as `"add`; use `y` to populate a register.
Mini.files now informs supporting language servers about file operations, allowing
imports to update after renames (with a bounded one-second request timeout).
Whether imports update immediately or a confirmation appears depends on the
language server and its settings.

File search and grep both include hidden files, respect ignore rules, and exclude
Git's internal directory. Open-buffer search includes unsaved text but skips
buffers in big-file mode or larger than 5 MiB, reporting the number skipped.

Grug-far opens alongside the file (below it on narrow terminals). The Paths input
shows the captured workspace or standalone search root. Edit the search and
replacement to inspect the preview, then press `Esc`, followed by `Space` then `r`
to replace. This shortcut applies only inside the search-and-replace window.
For selective replacement, use `Down` / `Up` in normal mode to browse result
lines without changing files. Press `Space n` to replace the current result line
and move to the next. This replaces all matches on that line;
`Space r` still replaces all results, including ones you skipped. The other
letter commands use `Space R` followed by the letter in the help header:
for example, `Space R c` closes the window and `Space R q` sends results to
quickfix. Press `g?` for the complete list. Its windows are temporary, so they
stay out of the normal buffer list and do not return with saved sessions.
Opening the interface does not save or replace anything. Project replacement
operates on files on disk; save or discard edits in affected buffers first.
A small upstream hook blocks replacement/sync of modified file buffers. Review
errors in the replacement results before retrying. Searches respect ignore rules
and include hidden files, while excluding `.git`.

## Validation

Run the isolated checks from this directory (installed plugins required;
the refinement suite also uses the TypeScript parser and Git):

```sh
nvim --headless -u NONE -i NONE -l tests/workspaces.lua
nvim --headless -u NONE -i NONE -l tests/startup.lua
nvim --headless -u NONE -i NONE -l tests/refinements.lua
nvim --headless -u NONE -i NONE -l tests/ui.lua
```

The checks use temporary history and snapshots; the full startup suite also uses
temporary cache and logs while loading the installed plugins.
The UI suite attaches real wide/narrow UIs, simulates SSH and an unprovisioned
host, and prints the location of its text screen captures. It does not measure
latency over a real SSH connection.

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

The dashboard shows six recent existing folders (press **1–6**) and actions for
opening a folder, all folders, recent files, config, plugin updates, and quitting.
**Open folder…** accepts a path with directory completion. Dashboard **Recent
files…** opens a standalone file and changes cwd to its parent. File pickers used
inside the editor add files to the current workspace. Browsing either explorer
does not switch workspaces.

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
Lualine shows the active folder or **Standalone**, including in `:LualinePreview`
presets.

History lives in `stdpath('state')/recent-folders.json`, separately from
`sessions/*.vim`. Existing snapshots seed history once. On the first open of each
folder, the newest legacy snapshot (including branch variants) becomes its single
session, with original copies preserved in `sessions/legacy/`. Later opens ignore
legacy variants. Missing folders remain available for removal in **All folders…**.
Snapshot deletion also removes legacy backups, but keeps folder history; forgetting
removes both. Deleting an active snapshot detaches it until explicitly reopened.

Use **Update plugins** for `vim.pack.update()`, and `:Mason` to inspect installed
tools. The existing installation checks remain enabled. Both explorers,
animations, and Tab/tabout behavior are retained.

Run the isolated checks from this directory (installed plugins required):

```sh
nvim --headless -u NONE -i NONE -l tests/workspaces.lua
nvim --headless -u NONE -i NONE -l tests/startup.lua
```

The checks use temporary history and snapshots; the full startup suite also uses
temporary cache and logs while loading the installed plugins.

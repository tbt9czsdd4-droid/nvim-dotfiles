-- Run with: nvim --headless -u NONE -i NONE -l tests/workspaces.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.stdpath 'data' .. '/site/pack/core/opt/persistence.nvim')
vim.opt.sessionoptions:remove 'blank'
local base = vim.fn.tempname()
vim.fn.mkdir(base, 'p')
local sessions = require 'config.sessions'
local project = require 'config.project'
local notifications, pickers = {}, {}
vim.notify = function(message) notifications[#notifications + 1] = message end
Snacks = { picker = { files = function(opts) pickers[#pickers + 1] = opts end } }
local confirm, input = vim.fn.confirm, vim.fn.input
local function choice(n)
    vim.fn.confirm = function(_, _, default)
        assert(default == 3 or default == 2)
        return n
    end
end
local function folder(name)
    local path = base .. '/' .. name
    vim.fn.mkdir(path, 'p')
    return path
end
local function equal(actual, expected) assert(vim.deep_equal(actual, expected), 'Expected ' .. vim.inspect(expected) .. ', got ' .. vim.inspect(actual)) end
local function file(path, text)
    vim.fn.writefile({ text or path }, path)
    return path
end
local function edit(path) vim.cmd.edit(vim.fn.fnameescape(path)) end
local function modify(text) vim.api.nvim_buf_set_lines(0, 0, -1, false, { text }) end
local function snapshot(root, suffix) return base .. '/sessions/' .. root:gsub('[\\/:]+', '%%') .. (suffix or '') .. '.vim' end
local a, b, nested = folder 'a', folder 'b', folder 'a/nested'
local outside = file(base .. '/outside.txt')
local afile, bfile = file(a .. '/a.txt'), file(b .. '/b.txt')
sessions.setup { dir = base .. '/sessions/', history_file = base .. '/recent.json' }
local seeded = folder 'seeded'
file(snapshot(seeded, '%%old-branch'), 'let g:seeded_session = 1')
local ok, err = xpcall(function()
    equal(sessions.folders()[1].root, seeded)
    equal(sessions.owner(), nil)
    assert(not require('persistence.config').options.branch)
    equal(require('persistence.config').options.need, 0)
    equal(sessions.open_directory(a), 'created')
    equal(pickers[#pickers].cwd, a)
    equal(sessions.owner(), a)
    edit(afile)
    vim.cmd.vsplit(vim.fn.fnameescape(outside))
    equal(project.root(), a)
    vim.cmd.lcd(b)
    equal(project.root(), a)
    assert(sessions.save())
    equal(vim.fn.filereadable(snapshot(a)), 1)
    equal(sessions.open_directory(b), 'created')
    equal(sessions.open_directory(a), 'loaded')
    equal(#vim.api.nvim_list_wins(), 2)
    equal(project.root(), a)
    vim.cmd.tabnew(vim.fn.fnameescape(bfile))
    assert(sessions.open_directory(b))
    assert(sessions.open_directory(a))
    equal(#vim.api.nvim_list_tabpages(), 2)
    equal(#vim.api.nvim_list_wins(), 3)
    equal(sessions.open_directory(nested), 'created')
    equal(sessions.owner(), nested)
    assert(vim.uv.fs_symlink(nested, base .. '/alias'))
    equal(sessions.open_directory(base .. '/alias'), 'loaded')
    equal(sessions.owner(), nested)
    equal(sessions.folders()[1].root, nested)
    equal(#sessions.folders(), 4)

    -- Branch changes cannot change session identity.
    vim.fn.mkdir(a .. '/.git', 'p')
    file(a .. '/.git/HEAD', 'ref: refs/heads/topic')
    equal(sessions.open_directory(a), 'loaded')
    local current = require('persistence').current()
    file(a .. '/.git/HEAD', 'ref: refs/heads/other')
    equal(require('persistence').current(), current)

    -- Cancel, invalid destinations, write failure, and successful Save all.
    edit(afile)
    modify 'unsaved'
    local original = vim.api.nvim_get_current_buf()
    choice(3)
    assert(not sessions.open_directory(b))
    equal(sessions.owner(), a)
    equal(vim.api.nvim_get_current_buf(), original)
    assert(vim.bo.modified)
    assert(not sessions.open_directory(base .. '/absent'))
    choice(1)
    vim.bo.readonly = true
    assert(not sessions.open_directory(b))
    equal(sessions.owner(), a)
    assert(vim.bo.modified)
    vim.bo.readonly = false
    local hidden = vim.fn.bufadd(outside)
    vim.fn.bufload(hidden)
    vim.api.nvim_buf_set_lines(hidden, 0, -1, false, { 'hidden modified buffer' })
    assert(sessions.open_directory(b))
    equal(vim.fn.readfile(afile), { 'unsaved' })
    equal(vim.fn.readfile(outside), { 'hidden modified buffer' })
    edit(bfile)
    modify 'discard this'
    choice(2)
    assert(sessions.open_directory(a))
    equal(vim.fn.readfile(bfile), { bfile })

    -- Unnamed writes and cancelled filename prompts.
    vim.cmd.enew()
    modify 'unnamed text'
    choice(1)
    vim.fn.input = function() return '' end
    assert(not sessions.open_directory(b))
    equal(sessions.owner(), a)
    assert(vim.bo.modified)
    vim.fn.input = function() return a .. '/new.txt' end
    assert(sessions.open_directory(b))
    equal(vim.fn.readfile(a .. '/new.txt'), { 'unnamed text' })
    vim.fn.input = input

    -- Non-file modified buffers must not silently bypass Save all.
    vim.cmd.enew()
    vim.bo.buftype = 'acwrite'
    modify 'special buffer'
    vim.bo.modified = true
    assert(not sessions.open_directory(a))
    equal(sessions.owner(), b)
    choice(2)
    assert(sessions.open_directory(a))

    -- Failed snapshots preserve the previous snapshot, workspace, and edits.
    local saved = vim.fn.readfile(snapshot(a))
    local save = require('persistence').save
    require('persistence').save = function() error 'simulated disk failure' end
    edit(afile)
    modify 'keep on failure'
    assert(not sessions.open_directory(b))
    equal(sessions.owner(), a)
    assert(vim.bo.modified)
    equal(vim.fn.readfile(snapshot(a)), saved)
    require('persistence').save = save
    assert(sessions.open_directory(b))

    -- Empty workspaces replace old file lists.
    assert(sessions.open_directory(a))
    vim.cmd 'silent! %bwipeout!'
    assert(sessions.open_directory(b))
    assert(sessions.open_directory(a))
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].buflisted then equal(vim.api.nvim_buf_get_name(buf), '') end
    end
    equal(pickers[#pickers].cwd, a)

    -- Dashboard files detach, change cwd, and cannot overwrite a snapshot.
    local empty = vim.fn.readfile(snapshot(a))
    assert(sessions.open_file_detached(outside))
    equal(sessions.owner(), nil)
    equal(vim.fn.getcwd(), base)
    equal(project.root(), base)
    assert(sessions.save())
    equal(vim.fn.readfile(snapshot(a)), empty)
    edit(afile)
    equal(project.root(), a)

    -- Missing folders appear only in full history; forgetting deletes both.
    local missing = folder 'missing'
    assert(sessions.open_directory(missing))
    assert(sessions.open_directory(b))
    vim.fn.delete(missing, 'd')
    local found = false
    for _, item in ipairs(sessions.folders()) do
        if item.root == missing then
            found = true
            assert(not item.available)
            assert(item.text:find 'unavailable')
        end
    end
    assert(found)
    for _, item in ipairs(sessions.folders { existing = true }) do
        assert(item.root ~= missing)
    end
    choice(2)
    assert(not sessions.forget(missing))
    choice(1)
    assert(sessions.forget(missing))
    equal(vim.fn.filereadable(snapshot(missing)), 0)
    for _, item in ipairs(sessions.folders()) do
        assert(item.root ~= missing)
    end
    assert(sessions.delete(b, { confirm = false }))
    equal(sessions.owner(), nil)
    equal(sessions.folders()[1].root, b)

    -- Newest legacy branch wins once; later variants are ignored.
    local legacy = folder 'legacy-project'
    local canonical, branch = snapshot(legacy), snapshot(legacy, '%%topic')
    file(canonical, 'let g:workspace_legacy = 1')
    file(branch, 'let g:workspace_legacy = 2')
    vim.uv.fs_utime(canonical, 1000, 1000)
    vim.uv.fs_utime(branch, 2000, 2000)
    assert(sessions.open_directory(legacy))
    equal(vim.g.workspace_legacy, 2)
    equal(vim.fn.filereadable(base .. '/sessions/legacy/' .. vim.fs.basename(canonical)), 1)
    equal(vim.fn.filereadable(base .. '/sessions/legacy/' .. vim.fs.basename(branch)), 1)
    assert(sessions.open_directory(a))
    file(branch, 'let g:workspace_legacy = 3')
    vim.g.workspace_legacy = 0
    assert(sessions.open_directory(legacy))
    equal(vim.g.workspace_legacy, 0)

    -- Persistent command-line buffers must survive workspace replacement.
    local ui_buffer = vim.api.nvim_create_buf(false, true)
    local ui2 = package.loaded['vim._core.ui2']
    local ui_window = vim.api.nvim_open_win(ui_buffer, false, { relative = 'editor', row = 0, col = 0, width = 10, height = 1 })
    package.loaded['vim._core.ui2'] = { bufs = { cmd = ui_buffer }, wins = { cmd = ui_window } }
    assert(sessions.open_directory(folder 'ui-project'))
    assert(vim.api.nvim_buf_is_valid(ui_buffer))
    assert(vim.api.nvim_win_is_valid(ui_window))
    package.loaded['vim._core.ui2'] = ui2

    -- The dashboard exposes only the latest six existing folders.
    for i = 1, 8 do
        assert(sessions.open_directory(folder('recent-' .. i)))
    end
    local recent = sessions.folders { existing = true, limit = 6 }
    equal(#recent, 6)
    equal(recent[1].root, base .. '/recent-8')
    equal(recent[6].root, base .. '/recent-3')

    -- Restoration errors stay visible and cannot overwrite the broken file.
    local broken = folder 'broken'
    file(snapshot(broken), 'this_is_not_a_command')
    assert(not sessions.open_directory(broken))
    equal(sessions.owner(), nil)
    assert(not require('persistence').active())
    assert(notifications[#notifications]:find 'Cannot restore workspace')
    equal(vim.fn.readfile(snapshot(broken)), { 'this_is_not_a_command' })
    for _, item in ipairs(sessions.folders()) do
        assert(item.root ~= broken)
    end
    equal(sessions.open_directory '/', 'detached')
    equal(sessions.owner(), nil)
    equal(sessions.open_directory(vim.env.HOME), 'detached')
    equal(sessions.owner(), nil)
    for _, item in ipairs(sessions.folders()) do
        assert(item.root ~= '/' and item.root ~= vim.env.HOME)
    end
end, debug.traceback)
sessions.detach()
vim.fn.confirm, vim.fn.input = confirm, input
if not ok then
    io.stderr:write(err .. '\nArtifacts: ' .. base .. '\n')
    vim.cmd 'cquit 1'
else
    print 'Workspace integration checks passed'
    vim.cmd 'qa!'
end

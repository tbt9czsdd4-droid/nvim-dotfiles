-- Integration checks using installed plugins and disposable files/state.
-- Run: nvim --headless -u NONE -i NONE -l tests/refinements.lua
local config = vim.fn.getcwd()
local base = vim.fn.tempname()
vim.fn.mkdir(base, 'p')
vim.env.XDG_STATE_HOME = base .. '/state'
vim.env.XDG_CACHE_HOME = base .. '/cache'
vim.env.NVIM_LOG_FILE = base .. '/nvim.log'
vim.opt.rtp:prepend(config)
dofile(config .. '/init.lua')
vim.opt.undodir = base .. '/undo'
vim.cmd 'filetype plugin indent on'
vim.cmd 'syntax enable'

local function equal(a, b) assert(vim.deep_equal(a, b), 'Expected ' .. vim.inspect(b) .. ', got ' .. vim.inspect(a)) end
local function wait(f, message) assert(vim.wait(5000, f, 20), message) end
local function keys(s) vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(s, true, false, true), 'xt', false) end
local function write(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    vim.fn.writefile(lines, path)
    return path
end
local function git(root, ...)
    local result = vim.system({ 'git', '-C', root, ... }, { text = true }):wait()
    assert(result.code == 0, result.stderr)
    return result.stdout
end
local function pick(key)
    vim.fn.maparg(key, 'n', false, true).callback()
    wait(function() return Snacks.picker.get()[1] ~= nil end, 'Picker did not open: ' .. key)
    return assert(Snacks.picker.get()[1], key .. ': ' .. vim.api.nvim_exec2('messages', { output = true }).output)
end
local function ready(p)
    wait(function() return not p:is_active() end, 'Picker did not finish')
end
local function close(p)
    p:close()
    vim.wait(80, function() return false end)
end
local sessions = require 'config.sessions'
local root = base .. '/project with spaces'
vim.fn.mkdir(root, 'p')
local file = write(root .. '/sample.txt', { 'needle alpha', 'second line' })
local hidden = write(root .. '/.settings', { 'needle hidden' })
local ignored = write(root .. '/ignored.txt', { 'needle ignored' })
write(root .. '/.gitignore', { 'ignored.txt' })
git(root, 'init', '-q')
git(root, 'add', '.')
git(root, '-c', 'user.name=Config Test', '-c', 'user.email=config@example.invalid', 'commit', '-qm', 'fixture')
write(root .. '/.git/private.txt', { 'needle internal' })
local outside = write(base .. '/outside.txt', { 'needle outside' })
git(base, 'init', '-q')
git(base, 'add', 'outside.txt')
git(base, '-c', 'user.name=Config Test', '-c', 'user.email=config@example.invalid', 'commit', '-qm', 'outside fixture')

local ok, err = xpcall(function()
    assert(sessions.open_directory(root, { picker = false }))
    vim.cmd.edit(file)

    -- Live grep includes dotfiles, respects ignores and never enters .git.
    local p = Snacks.picker.grep { cwd = root, search = 'needle' }
    ready(p)
    local found = {}
    for _, item in ipairs(p:items()) do
        found[vim.fs.basename(item.file)] = true
    end
    assert(found['sample.txt'] and found['.settings'], vim.inspect(found))
    assert(not found['ignored.txt'] and not found['private.txt'])
    close(p)

    -- Unsaved content is searchable; a large unloaded buffer stays unloaded.
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'UNSAVED_NEEDLE' })
    local bigpath = write(root .. '/big.txt', { string.rep('x', 5 * 1024 * 1024 + 1) })
    local big = vim.fn.bufadd(bigpath)
    vim.bo[big].buflisted = true
    local oversized = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_lines(oversized, 0, -1, false, { string.rep('y', 5 * 1024 * 1024 + 1) })
    local notifications, notify = {}, vim.notify
    vim.notify = function(message) notifications[#notifications + 1] = message end
    p = pick ' sB'
    ready(p)
    assert(vim.iter(p:items()):any(function(item) return item.line == 'UNSAVED_NEEDLE' end))
    assert(not vim.api.nvim_buf_is_loaded(big))
    assert(not vim.iter(p:items()):any(function(item) return item.buf == oversized end))
    vim.wait(50, function() return false end)
    assert(vim.iter(notifications):any(function(message) return message:find('skipped 2 large', 1, true) end), vim.inspect(notifications))
    vim.notify = notify
    close(p)
    vim.api.nvim_buf_delete(big, { force = true })
    vim.api.nvim_buf_delete(oversized, { force = true })
    vim.fn.delete(bigpath)
    vim.cmd 'edit!'

    -- Standard Mini surround/textobjects coexist with the existing delete and Flash keys.
    vim.cmd.enew()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'hello' })
    keys 'gsaiw"'
    equal(vim.api.nvim_get_current_line(), '"hello"')
    keys 'gsr"\''
    equal(vim.api.nvim_get_current_line(), "'hello'")
    keys "gsd'"
    equal(vim.api.nvim_get_current_line(), 'hello')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'call(first, second)' })
    vim.api.nvim_win_set_cursor(0, { 1, 6 })
    keys 'ciachanged<Esc>'
    equal(vim.api.nvim_get_current_line(), 'call(changed, second)')
    assert(vim.fn.maparg('s', 'n', false, true).desc == 'Flash')
    equal(vim.fn.maparg('d', 'n'), '"_d')
    vim.cmd 'bwipeout!'

    -- Highlighting stays active; new windows and legacy sessions stay unfolded.
    local tsfile = write(root .. '/folds.ts', { 'function example() {', '  const value = 1;', '  return value;', '}', '' })
    vim.cmd.edit(tsfile)
    assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()])
    local function unfolded()
        equal(vim.wo.foldenable, false)
        equal(vim.wo.foldmethod, 'manual')
        equal(vim.wo.foldexpr, '0')
        equal(vim.fn.foldclosed(1), -1)
    end
    unfolded()
    vim.cmd 'vsplit'
    unfolded()
    vim.cmd 'tab split'
    unfolded()
    local tabs, windows = #vim.api.nvim_list_tabpages(), #vim.api.nvim_list_wins()
    -- Create a real old-style snapshot with closed syntax folds in every window.
    local sessionoptions = vim.o.sessionoptions
    assert(not vim.tbl_contains(vim.opt.sessionoptions:get(), 'folds'))
    vim.opt.sessionoptions:append 'folds'
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        vim.api.nvim_win_call(win, function()
            vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            vim.wo.foldmethod = 'expr'
            vim.wo.foldenable = true
            vim.cmd 'normal! zx'
            vim.cmd 'normal! zM'
            assert(vim.fn.foldclosed(1) > 0)
        end)
    end
    assert(sessions.reset_to_starter())
    vim.o.sessionoptions = sessionoptions
    assert(sessions.open_directory(root, { picker = false }))
    equal(#vim.api.nvim_list_tabpages(), tabs)
    equal(#vim.api.nvim_list_wins(), windows)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        vim.api.nvim_win_call(win, function()
            unfolded()
            equal(vim.api.nvim_buf_get_name(0), tsfile)
        end)
    end
    vim.cmd 'vsplit'
    unfolded()
    assert(sessions.save())
    local snapshot = table.concat(vim.fn.readfile(vim.v.this_session), '\n')
    assert(not snapshot:find('foldmethod=', 1, true), 'New snapshot contains fold options')
    vim.cmd 'tabonly'
    vim.cmd 'only'
    vim.cmd.enew()
    vim.bo.filetype = 'config_test_no_parser'
    assert(not vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()])

    -- Project-local Prettier wins, without installing a formatter for the test.
    local prettier = write(root .. '/node_modules/.bin/prettier', { '#!/bin/sh', "printf 'formatted\\n'" })
    vim.fn.setfperm(prettier, 'rwxr-xr-x')
    local js = write(root .. '/format.js', { 'let x=1' })
    vim.cmd.edit(js)
    local conform = require 'conform'
    equal(conform.get_formatter_info('prettier', 0).command, prettier)
    conform.format { async = false, lsp_format = 'never' }
    equal(vim.api.nvim_get_current_line(), 'formatted')
    vim.cmd 'edit!'
    assert(not vim.g.autoformat)
    assert(not vim.lsp.is_enabled 'stylua')
    assert(vim.lsp.config.rust_analyzer.settings['rust-analyzer'].cargo == nil)

    -- Hunk operators update the Git index, then reset buffer text from it.
    vim.cmd.edit(file)
    wait(function() return MiniDiff.get_buf_data(0) ~= nil end, 'Git diff did not attach')
    vim.api.nvim_buf_set_lines(0, 0, 1, false, { 'staged alpha' })
    wait(function() return #MiniDiff.get_buf_data(0).hunks > 0 end, 'Missing hunk')
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    keys 'ghgh'
    wait(function() return git(root, 'show', ':sample.txt'):find('staged alpha', 1, true) ~= nil end, 'Hunk was not staged')
    wait(function() return #MiniDiff.get_buf_data(0).hunks == 0 end, 'Reference did not update')
    vim.api.nvim_buf_set_lines(0, 0, 1, false, { 'discard me' })
    wait(function() return #MiniDiff.get_buf_data(0).hunks > 0 end, 'Missing reset hunk')
    keys 'gHgh'
    equal(vim.api.nvim_buf_get_lines(0, 0, 1, false), { 'staged alpha' })
    vim.cmd 'write'

    -- Workspace Git views keep the workspace root when editing an outside file.
    vim.cmd.edit(outside)
    for _, key in ipairs { ' gs', ' gd', ' gl' } do
        p = pick(key)
        equal(p.opts.cwd, root)
        close(p)
    end
    p = pick ' gf'
    ready(p)
    assert(vim.iter(p:items()):any(function(item) return item.text:find('outside fixture', 1, true) ~= nil end))
    close(p)

    -- Replacement captures its root, handles spaces, and does not save on open.
    local cwd = vim.fn.getcwd()
    vim.fn.maparg(' sr', 'n', false, true).callback()
    local grug = require 'grug-far'
    local instance = grug.get_instance()
    local is_ready = false
    instance:when_ready(function() is_ready = true end)
    wait(function() return is_ready end, 'Replacement UI did not open')
    for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(instance:get_buf(), 'n')) do
        assert(not mapping.lhs:find('\\', 1, true), 'German keyboard-unfriendly shortcut: ' .. mapping.lhs)
    end
    equal(vim.fn.maparg(' Rc', 'n', false, true).buffer, 1)
    equal(vim.fn.getcwd(), cwd)
    equal(vim.api.nvim_win_get_width(0), vim.o.columns)
    local contents = table.concat(vim.api.nvim_buf_get_lines(instance:get_buf(), 0, -1, false), '\n')
    assert(contents:find(root:gsub(' ', '\\ '), 1, true), contents)
    equal(vim.fn.readfile(hidden), { 'needle hidden' })
    instance:update_input_values({ search = 'needle', replacement = 'replaced' }, false)
    wait(
        function() return instance:get_status_info().stats ~= nil and instance:get_status_info().status == 'success' end,
        'Replacement preview did not complete'
    )

    -- A modified target blocks disk replacement; the same action works once saved/discarded.
    local hiddenbuf = vim.fn.bufadd(hidden)
    vim.fn.bufload(hiddenbuf)
    vim.api.nvim_buf_set_lines(hiddenbuf, 0, -1, false, { 'unsaved hidden' })
    instance:replace()
    wait(function() return instance:get_status_info().status == 'error' end, 'Modified buffer did not block replacement')
    equal(vim.fn.readfile(hidden), { 'needle hidden' })
    equal(vim.api.nvim_buf_get_lines(hiddenbuf, 0, -1, false), { 'unsaved hidden' })
    vim.api.nvim_buf_call(hiddenbuf, function() vim.cmd 'edit!' end)
    instance:replace()
    wait(function() return instance:get_status_info().status == 'success' end, 'Replacement failed')
    equal(vim.fn.readfile(hidden), { 'replaced hidden' })
    equal(vim.fn.readfile(ignored), { 'needle ignored' })
    equal(vim.fn.readfile(outside), { 'needle outside' })
    equal(vim.fn.readfile(root .. '/.git/private.txt'), { 'needle internal' })
    vim.cmd 'stopinsert'
    keys ' Rc'
    wait(function() return not vim.api.nvim_buf_is_valid(instance:get_buf()) end, 'Grug-far close shortcut did not work')

    -- Light statusline cleanup still exposes non-default file formats.
    local x = require('lualine').get_config().sections.lualine_x
    vim.bo.fileencoding = 'utf-8'
    vim.bo.fileformat = 'unix'
    assert(not x[1].cond() and not x[2].cond())
    vim.bo.fileencoding = 'latin1'
    vim.bo.fileformat = 'dos'
    assert(x[1].cond() and x[2].cond())
    equal(vim.fn.exists ':LualinePreview', 0)
end, debug.traceback)
sessions.detach()
if not ok then
    io.stderr:write(err .. '\nArtifacts: ' .. base .. '\n')
    vim.cmd 'cquit 1'
end
print 'Editing, search, Git, folding, formatting, and replacement checks passed'
vim.cmd 'qa!'

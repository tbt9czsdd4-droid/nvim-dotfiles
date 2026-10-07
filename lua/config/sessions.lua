local M = {}
local uv = vim.uv
local owner
local dir
local history_file
local stdin = false

local function normalize(path)
    path = uv.fs_realpath(path) or vim.fn.fnamemodify(path, ':p')
    path = vim.fs.normalize(path)
    return path == '/' and path or path:gsub('/+$', '')
end

local function protected(path) return path == '/' or path == normalize(vim.env.HOME) end
local function label(path) return vim.fn.fnamemodify(path, ':~') end
local function fail(message) vim.notify(message, vim.log.levels.ERROR) end
local function snapshot(root) return dir .. root:gsub('[\\/:]+', '%%') .. '.vim' end

local function atomic_write(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    local temporary = path .. '.' .. uv.os_getpid() .. '.tmp'
    local ok, err = pcall(function()
        assert(vim.fn.writefile(lines, temporary, 'b') == 0, 'Cannot write ' .. temporary)
        assert(uv.fs_rename(temporary, path))
    end)
    if not ok then
        vim.fn.delete(temporary)
        error(err)
    end
end

local function write_history(index) atomic_write(history_file, { vim.json.encode(index) }) end

local function history()
    local index = { version = 1, folders = {} }
    if vim.fn.filereadable(history_file) == 1 then
        local stored = vim.json.decode(table.concat(vim.fn.readfile(history_file), '\n'))
        assert(type(stored) == 'table' and type(stored.folders) == 'table', 'Invalid folder history: ' .. history_file)
        index.folders = stored.folders
    end
    return index
end

function M.folders(opts)
    opts = opts or {}
    local items = {}
    for root, opened in pairs(history().folders) do
        local exists = vim.fn.isdirectory(root) == 1
        if not protected(root) and (exists or not opts.existing) then
            items[#items + 1] =
                { root = root, file = root, dir = true, opened = opened, available = exists, text = label(root) .. (exists and '' or ' [unavailable]') }
        end
    end
    table.sort(items, function(a, b)
        if a.opened == b.opened then return a.root < b.root end
        return a.opened > b.opened
    end)
    if opts.limit then
        while #items > opts.limit do
            table.remove(items)
        end
    end
    return items
end

local function modified_buffers()
    return vim.tbl_filter(function(buf) return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified end, vim.api.nvim_list_bufs())
end

local function can_transition()
    local buffers = modified_buffers()
    if #buffers == 0 then return true end
    local choice = vim.fn.confirm('Save modified buffers before leaving this workspace?', '&Save all\n&Discard\n&Cancel', 3)
    if choice == 2 then return true end
    if choice ~= 1 then return false end
    for _, buf in ipairs(buffers) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified and vim.bo[buf].buftype == '' then
            local ok, err = pcall(function()
                local name = vim.api.nvim_buf_get_name(buf)
                if name == '' then
                    name = vim.fn.input { prompt = 'Save unnamed buffer as: ', completion = 'file' }
                    if name == '' then error 'Saving the unnamed buffer was cancelled' end
                    name = vim.fn.fnamemodify(vim.fn.expand(name), ':p')
                end
                vim.api.nvim_buf_call(buf, function() vim.cmd('write ' .. vim.fn.fnameescape(name)) end)
            end)
            if not ok then
                fail('Workspace switch aborted: ' .. tostring(err))
                return false
            end
        end
    end
    if #modified_buffers() > 0 then
        fail 'Workspace switch aborted: modified buffers remain'
        return false
    end
    return true
end

local function has_files()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].buflisted and vim.bo[buf].buftype == '' then
            local name = vim.api.nvim_buf_get_name(buf)
            if name ~= '' and vim.fn.isdirectory(name) == 0 then return true end
        end
    end
    return false
end

function M.save()
    if not owner then return true end
    if vim.fn.isdirectory(owner) == 0 then
        fail('Cannot save workspace: folder no longer exists: ' .. owner)
        return false
    end
    local cwd, destination = vim.fn.getcwd(), snapshot(owner)
    -- Write next to the snapshot, then rename: a failed save keeps the old one.
    local temporary = destination .. '.' .. uv.os_getpid() .. '.tmp'
    local ok, err = pcall(function()
        vim.fn.mkdir(dir, 'p')
        -- :mksession records the current directory, so save from the workspace root.
        vim.api.nvim_set_current_dir(owner)
        vim.cmd('mksession! ' .. vim.fn.fnameescape(temporary))
        assert(uv.fs_rename(temporary, destination))
    end)
    vim.fn.delete(temporary)
    if vim.fn.isdirectory(cwd) == 1 then vim.api.nvim_set_current_dir(cwd) end
    if not ok then
        fail('Cannot save workspace: ' .. tostring(err))
        return false
    end
    vim.v.this_session = destination
    return true
end

local function prepare_transition() return can_transition() and M.save() end

local function clear_workspace()
    pcall(function() require('mini.files').close() end)
    vim.cmd 'silent! %argdelete'
    -- ui2 keeps persistent command/message buffers, including deferred callbacks
    -- which still reference them after a confirmation prompt closes.
    local ui2 = package.loaded['vim._core.ui2']
    local ui_buffers = type(ui2) == 'table' and ui2.bufs or {}
    local ui_windows = type(ui2) == 'table' and ui2.wins or {}
    local current = vim.api.nvim_get_current_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win ~= current and vim.api.nvim_win_is_valid(win) and not vim.tbl_contains(ui_windows or {}, win) then vim.api.nvim_win_close(win, true) end
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and not vim.tbl_contains(ui_buffers or {}, buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
    end
    -- Bufferline's tab order is per workspace; the next snapshot restores its own.
    vim.g.BufferlinePositions = nil
end

function M.detach() owner = nil end

function M.open_directory(path, opts)
    opts = opts or {}
    if not path or path == '' then return false end
    path = normalize(path)
    if vim.fn.isdirectory(path) == 0 then
        fail('Folder does not exist: ' .. path)
        return false
    end
    if not prepare_transition() then return false end
    M.detach()
    clear_workspace()
    vim.api.nvim_set_current_dir(path)
    local result = 'detached'
    if not protected(path) then
        local file = snapshot(path)
        result = vim.fn.filereadable(file) == 1 and 'loaded' or 'created'
        if result == 'loaded' then
            -- Not silent!: restoration errors must be reported.
            local ok, err = pcall(vim.cmd, 'source ' .. vim.fn.fnameescape(file))
            vim.api.nvim_set_current_dir(path)
            -- :mksession scripts contain :only, which also closes UI floats.
            -- Recreate those targets before ui2's deferred prompt cleanup runs.
            local ui2 = package.loaded['vim._core.ui2']
            if type(ui2) == 'table' and ui2.check_targets and ui2.cfg.enable ~= false and #vim.api.nvim_list_uis() > 0 then ui2.check_targets() end
            if not ok then
                fail('Cannot restore workspace (automatic saving is disabled): ' .. tostring(err))
                return false
            end
        end
        owner = path
        local ok, err = pcall(function()
            local index = history()
            local seconds, microseconds = uv.gettimeofday()
            local now = seconds + microseconds / 1000000
            -- Keep explicit opens ordered even within the same second.
            for _, opened in pairs(index.folders) do
                now = math.max(now, opened + 0.000001)
            end
            index.folders[path] = now
            write_history(index)
        end)
        if not ok then fail('Cannot update folder history: ' .. tostring(err)) end
    end
    if opts.picker ~= false and not has_files() then Snacks.picker.files { cwd = path } end
    return result
end

-- Complete one entire path rather than treating spaces as word separators.
function M.complete_directory(findstart, base)
    if findstart == 1 then return 0 end
    return vim.fn.getcompletion(base, 'dir')
end

function M.prompt_directory()
    local cwd = vim.fn.getcwd()
    local win = Snacks.input({
        prompt = 'Open folder',
        default = cwd:gsub('/+$', '') .. '/',
        completion = 'dir',
        win = {
            keys = {
                i_esc = { '<Esc>', { 'cmp_close', 'cancel' }, mode = 'i', expr = true },
                i_up = { '<Up>', { 'cmp_select_prev', 'hist_up' }, mode = { 'i', 'n' }, expr = true },
                i_down = { '<Down>', { 'cmp_select_next', 'hist_down' }, mode = { 'i', 'n' }, expr = true },
                i_ctrl_k = { '<C-k>', { 'cmp_select_prev', 'hist_up' }, mode = { 'i', 'n' }, expr = true },
                i_ctrl_j = { '<C-j>', { 'cmp_select_next', 'hist_down' }, mode = { 'i', 'n' }, expr = true },
            },
        },
    }, function(path)
        if not path or path == '' then return end
        path = vim.fn.expand(path)
        if not vim.startswith(path, '/') then path = cwd .. '/' .. path end
        M.open_directory(path)
    end)
    -- Snacks reapplies window options when the dialog grows with the path.
    win.opts.bo.completefunc = "v:lua.require'config.sessions'.complete_directory"
    vim.bo[win.buf].completefunc = win.opts.bo.completefunc
end

function M.restore_current() return M.open_directory(vim.fn.getcwd()) end

function M.restore_last()
    local item = M.folders({ existing = true, limit = 1 })[1]
    if item then return M.open_directory(item.root) end
    vim.notify 'No recent folders'
end

function M.delete(root, opts)
    opts = opts or {}
    root = normalize(root)
    if opts.confirm ~= false and vim.fn.confirm('Delete the saved session for ' .. label(root) .. '?', '&Delete\n&Cancel', 2) ~= 1 then return false end
    local file = snapshot(root)
    if vim.fn.filereadable(file) == 1 and vim.fn.delete(file) ~= 0 then
        fail('Cannot delete session: ' .. file)
        return false
    end
    if owner == root then M.detach() end
    return true
end

function M.forget(root)
    root = normalize(root)
    if vim.fn.confirm('Forget ' .. label(root) .. ' and delete its saved session?', '&Forget\n&Cancel', 2) ~= 1 then return false end
    if not M.delete(root, { confirm = false }) then return false end
    local index = history()
    index.folders[root] = nil
    write_history(index)
    return true
end

function M.delete_current(opts)
    if owner then return M.delete(owner, opts) end
    vim.notify('There is no active session to delete', vim.log.levels.WARN)
    return false
end

function M.select()
    Snacks.picker.pick {
        title = 'Folders (<C-d> forget)',
        finder = function() return M.folders() end,
        format = 'text',
        show_empty = true,
        sort = { fields = { 'score:desc', 'idx' } },
        confirm = function(picker, item)
            if not item then return end
            if not item.available then
                vim.notify('Folder is unavailable: ' .. item.root, vim.log.levels.WARN)
                return
            end
            picker:close()
            vim.schedule(function() M.open_directory(item.root) end)
        end,
        actions = {
            forget_folder = function(picker, item)
                if item and M.forget(item.root) then picker:refresh() end
            end,
        },
        win = {
            input = { keys = { ['<C-d>'] = { 'forget_folder', mode = { 'n', 'i' } } } },
            list = { keys = { ['<C-d>'] = 'forget_folder' } },
        },
    }
end

function M.open_file_detached(path)
    path = normalize(path)
    if vim.fn.isdirectory(vim.fs.dirname(path)) == 0 then
        fail('File parent folder does not exist: ' .. path)
        return false
    end
    if not prepare_transition() then return false end
    M.detach()
    clear_workspace()
    vim.api.nvim_set_current_dir(vim.fs.dirname(path))
    vim.cmd.edit(vim.fn.fnameescape(path))
    return true
end

-- Only the dashboard uses this action. Editor pickers keep their normal confirm.
function M.recent_files()
    Snacks.picker.recent {
        filter = false,
        show_empty = true,
        confirm = function(picker, item)
            picker:close()
            if item then vim.schedule(function() M.open_file_detached(item.file) end) end
        end,
    }
end

function M.reset_to_starter()
    if not prepare_transition() then return false end
    M.detach()
    clear_workspace()
    require('mini.starter').open(vim.api.nvim_get_current_buf())
    return true
end

function M.restart_to_starter()
    if not M.reset_to_starter() then return false end
    vim.cmd 'restart!'
    return true
end

function M.owner() return owner end

function M.setup(opts)
    opts = opts or {}
    dir = opts.dir or vim.fn.stdpath 'state' .. '/sessions/'
    history_file = opts.history_file or vim.fn.stdpath 'state' .. '/recent-folders.json'
    M.detach()
    local group = vim.api.nvim_create_augroup('folder-workspaces', { clear = true })
    vim.api.nvim_create_autocmd('VimLeavePre', { group = group, callback = function() M.save() end })
    vim.api.nvim_create_autocmd('StdinReadPre', { group = group, callback = function() stdin = true end })
    local directory
    local no_arguments = vim.fn.argc() == 0
    if vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then directory = normalize(vim.fn.argv(0)) end
    vim.api.nvim_create_autocmd('VimEnter', {
        group = group,
        once = true,
        callback = function()
            vim.schedule(function()
                if stdin then return end
                if directory then
                    M.open_directory(directory)
                elseif no_arguments then
                    require('mini.starter').open()
                end
            end)
        end,
    })
end

return M

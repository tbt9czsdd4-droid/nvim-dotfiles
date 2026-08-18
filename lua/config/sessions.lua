local M = {}

local uv = vim.uv
local owner

local function normalize(path)
    path = uv.fs_realpath(path) or vim.fn.fnamemodify(path, ':p')
    path = vim.fs.normalize(path)

    if path ~= '/' then path = path:gsub('/+$', '') end
    return path
end

local function root_from_session(session)
    local name = vim.fn.fnamemodify(session, ':t:r')
    local encoded = vim.split(name, '%%', { plain = true })[1]
    return normalize(encoded:gsub('%%', '/'))
end

local function is_within(path, root) return path == root or vim.startswith(path, root == '/' and root or root .. '/') end

local function with_cwd(path, callback)
    local previous = uv.cwd()
    vim.api.nvim_set_current_dir(path)
    local ok, result = pcall(callback)

    if previous and uv.fs_stat(previous) then vim.api.nvim_set_current_dir(previous) end
    if not ok then error(result) end
    return result
end

local function session_for_root(root)
    return with_cwd(root, function()
        local persistence = require 'persistence'
        local branch = persistence.current()
        local fallback = persistence.current { branch = false }

        if vim.fn.filereadable(branch) == 1 then return branch end
        if vim.fn.filereadable(fallback) == 1 then return fallback end
    end)
end

local function session_roots()
    local roots = {}

    for _, session in ipairs(require('persistence').list()) do
        local root = root_from_session(session)
        if uv.fs_stat(root) then roots[root] = true end
    end

    return vim.tbl_keys(roots)
end

local function containing_session(path)
    path = normalize(path)
    local match

    for _, root in ipairs(session_roots()) do
        if is_within(path, root) and session_for_root(root) and (not match or #root > #match) then match = root end
    end

    return match
end

local function modified_buffers()
    local result = {}

    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buffer) and vim.bo[buffer].modified then
            local name = vim.api.nvim_buf_get_name(buffer)
            table.insert(result, name ~= '' and vim.fn.fnamemodify(name, ':~:.') or '[No Name]')
        end
    end

    return result
end

local function has_file_buffers()
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buffer) and vim.bo[buffer].buftype == '' then
            local filetype = vim.bo[buffer].filetype
            local name = vim.api.nvim_buf_get_name(buffer)

            if name ~= '' and not vim.tbl_contains({ 'gitcommit', 'gitrebase', 'jj' }, filetype) then return true end
        end
    end

    return false
end

local function can_transition()
    local modified = modified_buffers()
    if #modified == 0 then return true end

    vim.notify('Session switch aborted; save or discard modified buffers:\n' .. table.concat(modified, '\n'), vim.log.levels.WARN)
    return false
end

local function wipe_buffers() vim.cmd 'silent! %bwipeout!' end

local function close_explorer()
    pcall(function() require('mini.files').close() end)
end

function M.save()
    local persistence = require 'persistence'
    if not owner or not persistence.active() then return false end

    persistence.fire 'SavePre'
    if not has_file_buffers() then return false end

    vim.api.nvim_set_current_dir(owner)
    persistence.save()
    persistence.fire 'SavePost'
    return true
end

local function save_before_transition()
    if not can_transition() then return false end
    M.save()
    return true
end

local function activate(root)
    owner = normalize(root)
    vim.api.nvim_set_current_dir(owner)
    require('persistence').start()
end

local function load_root(root)
    local session = session_for_root(root)
    if not session then return false end

    close_explorer()
    wipe_buffers()
    activate(root)
    require('persistence').load()
    return true
end

function M.open_directory(path, opts)
    opts = opts or {}
    path = normalize(path)
    if not save_before_transition() then return nil end

    local root = containing_session(path)
    if root then
        load_root(root)
        return 'loaded'
    end

    if not opts.startup then wipe_buffers() end
    activate(path)
    return 'created'
end

function M.restore_current()
    if not save_before_transition() then return end

    local root = containing_session(uv.cwd())
    if root then load_root(root) end
end

function M.select()
    local items = {}

    for _, root in ipairs(session_roots()) do
        local session = session_for_root(root)
        if session then
            table.insert(items, {
                root = root,
                session = session,
                mtime = assert(uv.fs_stat(session)).mtime.sec,
            })
        end
    end

    table.sort(items, function(a, b) return a.mtime > b.mtime end)
    vim.ui.select(items, {
        prompt = 'Select a session: ',
        format_item = function(item) return vim.fn.fnamemodify(item.root, ':p:~') end,
    }, function(item)
        if not item then return end
        vim.schedule(function()
            if save_before_transition() then load_root(item.root) end
        end)
    end)
end

function M.restore_last()
    local session

    for _, candidate in ipairs(require('persistence').list()) do
        if uv.fs_stat(root_from_session(candidate)) then
            session = candidate
            break
        end
    end

    if not session or not can_transition() then return end

    M.save()
    close_explorer()
    wipe_buffers()
    activate(root_from_session(session))
    require('persistence').fire 'LoadPre'
    vim.cmd('silent! source ' .. vim.fn.fnameescape(session))
    require('persistence').fire 'LoadPost'
end

function M.detach()
    owner = nil
    require('persistence').stop()
end

function M.open_file_detached(path)
    path = normalize(path)
    if not save_before_transition() then return end

    M.detach()
    wipe_buffers()
    vim.cmd.edit(vim.fn.fnameescape(path))
end

function M.recent_files(local_opts)
    require('mini.extra').pickers.oldfiles(local_opts, {
        source = {
            choose = function(item)
                local path = vim.fn.fnamemodify(item, ':p')
                vim.schedule(function() M.open_file_detached(path) end)
            end,
        },
    })
end

function M.owner() return owner end

function M.setup()
    local persistence = require 'persistence'
    persistence.setup {}

    vim.api.nvim_create_autocmd('User', {
        group = vim.api.nvim_create_augroup('session-owner', { clear = true }),
        pattern = 'PersistenceSavePre',
        callback = function()
            if owner then vim.api.nvim_set_current_dir(owner) end
        end,
        desc = 'Keep session saves attached to their owner directory',
    })

    local directory
    if vim.fn.argc() == 1 then
        local path = vim.fn.fnamemodify(vim.fn.argv(0), ':p')
        if vim.fn.isdirectory(path) == 1 then directory = path end
    end

    if not directory then
        M.detach()
        return
    end

    vim.api.nvim_create_autocmd('VimEnter', {
        once = true,
        callback = function()
            vim.schedule(function()
                vim.cmd 'silent! %argdelete'
                M.open_directory(directory, { startup = true })
            end)
        end,
    })
end

return M

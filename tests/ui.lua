-- Exercise actual attached UIs (including ui2), using isolated state and files.
-- Run: nvim --headless -u NONE -i NONE -l tests/ui.lua
local config, data = vim.fn.getcwd(), vim.fn.stdpath 'data'
local base = assert(vim.uv.fs_mkdtemp((vim.env.TMPDIR or '/tmp') .. '/nvim-ui-XXXXXX'))
vim.fn.mkdir(base .. '/project', 'p')
vim.fn.writefile({ 'hello world' }, base .. '/project/sample.txt')
vim.fn.writefile({ 'second file' }, base .. '/project/second.txt')
vim.fn.mkdir(base .. '/folder with spaces/child one', 'p')
vim.fn.mkdir(base .. '/folder with spaces/child two', 'p')
local child, replies, stderr, grid, unpacker, exited, stdin, stdout, errorpipe
local seq = 0
local function wait(f, why)
    local deadline = vim.uv.hrtime() + 10e9
    while not f() do
        -- RPC predicates process events themselves; use a wall-clock deadline
        -- so repeated RPC replies cannot keep restarting vim.wait's timeout.
        assert(vim.uv.hrtime() < deadline, why .. '\n' .. table.concat(stderr or {}, '\n'))
        vim.wait(10)
    end
end
local function receive(err, bytes)
    assert(not err, err)
    if not bytes then return end
    local pos = 1
    while pos <= #bytes do
        local message
        message, pos = unpacker(bytes, pos)
        if message then
            if message[1] == 1 then
                replies[message[2]] = message
            elseif message[1] == 2 and message[2] == 'redraw' then
                for _, event in ipairs(message[3]) do
                    if event[1] == 'grid_line' then
                        for i = 2, #event do
                            local update = event[i]
                            if update[1] == 1 then
                                local row, col = update[2] + 1, update[3] + 1
                                grid[row] = grid[row] or {}
                                for _, cell in ipairs(update[4]) do
                                    for _ = 1, cell[3] or 1 do
                                        grid[row][col], col = cell[1], col + 1
                                    end
                                end
                            end
                        end
                    elseif event[1] == 'grid_clear' then
                        grid = {}
                    end
                end
            end
        end
    end
end
local function rpc(method, args)
    seq = seq + 1
    local id = seq
    stdin:write(vim.mpack.encode { 0, id, method, args or {} })
    wait(function() return replies[id] ~= nil or exited end, 'RPC timeout: ' .. method)
    local reply = assert(replies[id], 'Child exited: ' .. tostring(exited) .. '\n' .. table.concat(stderr, '\n'))
    replies[id] = nil
    assert(reply[3] == vim.NIL, vim.inspect(reply[3]))
    return reply[4]
end
local function lua(code, args) return rpc('nvim_exec_lua', { code, args or {} }) end
local function input(keys)
    rpc('nvim_input', { keys })
    vim.wait(100, function() return false end)
end
local function snapshot(name)
    rpc('nvim_command', { 'redraw!' })
    vim.wait(100, function() return false end)
    local lines = {}
    for i = 1, #grid do
        lines[i] = table.concat(grid[i] or {})
    end
    vim.fn.writefile(lines, base .. '/' .. name .. '.txt')
end
local function stop()
    if child then
        if not exited then stdin:write(vim.mpack.encode { 2, 'nvim_command', { 'qa!' } }) end
        vim.wait(3000, function() return exited ~= nil end)
        if not exited then
            child:kill(9)
            vim.wait(1000, function() return exited ~= nil end)
        end
        for _, handle in ipairs { stdin, stdout, errorpipe, child } do
            if not handle:is_closing() then handle:close() end
        end
        child = nil
    end
end
local function start(name, width, ssh, fresh)
    replies, stderr, grid, unpacker, exited = {}, {}, {}, vim.mpack.Unpacker(), nil
    local env = {
        XDG_STATE_HOME = base .. '/' .. name .. '/state',
        XDG_CACHE_HOME = base .. '/' .. name .. '/cache',
        NVIM_LOG_FILE = base .. '/' .. name .. '/nvim.log',
        SSH_CONNECTION = ssh and 'test-client 1 test-host 22' or '',
        SSH_TTY = '',
    }
    vim.fn.mkdir(base .. '/' .. name, 'p')
    if fresh then
        env.XDG_DATA_HOME = base .. '/' .. name .. '/data'
        vim.fn.mkdir(env.XDG_DATA_HOME .. '/nvim/site', 'p')
        assert(vim.uv.fs_symlink(data .. '/site/pack', env.XDG_DATA_HOME .. '/nvim/site/pack'))
    end
    local command = { 'nvim', '--embed', '-i', 'NONE', '-u', config .. '/init.lua' }
    if not ssh then vim.list_extend(command, { '--cmd', 'lua vim.env.SSH_CONNECTION=nil; vim.env.SSH_TTY=nil' }) end
    local environment = {}
    for key, value in pairs(vim.tbl_extend('force', vim.fn.environ(), env)) do
        environment[#environment + 1] = key .. '=' .. value
    end
    stdin, stdout, errorpipe = vim.uv.new_pipe(), vim.uv.new_pipe(), vim.uv.new_pipe()
    table.remove(command, 1)
    child = assert(
        vim.uv.spawn('nvim', { args = command, env = environment, stdio = { stdin, stdout, errorpipe } }, vim.schedule_wrap(function(code) exited = code end))
    )
    stdout:read_start(vim.schedule_wrap(receive))
    errorpipe:read_start(vim.schedule_wrap(function(_, bytes)
        if bytes then stderr[#stderr + 1] = bytes end
    end))
    rpc('nvim_ui_attach', { width, 40, { rgb = true, ext_linegrid = true } })
    wait(function() return lua [=[return vim.bo.filetype == 'ministarter']=] end, 'Dashboard did not open')
    assert(lua [=[return #MiniStarter.content_to_items(MiniStarter.get_content()) == 6]=])
    snapshot(name .. '-dashboard')
end
local ok, err = xpcall(function()
    for _, case in ipairs { { 'wide', 140, false }, { 'ssh-narrow', 80, true } } do
        start(case[1], case[2], case[3])
        assert(lua [=[return #vim.api.nvim_list_uis() == 1]=])
        assert(lua [=[return require('vim._core.ui2').msg ~= nil and vim.o.cmdheight == 0]=])
        if case[3] then assert(lua [=[return vim.g.clipboard.name == 'OSC 52' and package.loaded['mini.animate'] == nil]=]) end
        lua([[vim.api.nvim_set_current_dir(...); _G.original_ui_input = vim.ui.input]], { base })
        assert(lua [=[return vim.fn.maparg(' E', 'n') == '' and not Snacks.config.explorer.enabled]=])

        -- Both dashboard prefixes open a directory dialog; Escape cancels it.
        for _, key in ipairs { 'o', 'O' } do
            input(key)
            wait(function() return lua [=[return vim.bo.filetype == 'snacks_input']=] end, 'Folder dialog did not open: ' .. key)
            assert(lua('return vim.api.nvim_get_current_line() == ...', { base .. '/' }))
            input '<Esc>'
            wait(function() return lua [=[return vim.bo.filetype == 'ministarter']=] end, 'Folder dialog did not cancel')
        end

        input 'O'
        input('<C-u>' .. base .. '/' .. string.rep('long-path-', 20))
        assert(lua('return vim.api.nvim_win_get_width(0) <= ... - 2', { case[2] }))
        input('<C-u>' .. base .. '/folder with spaces/child')
        input '<Tab>'
        wait(function() return lua [=[return vim.fn.pumvisible() == 1]=] end, 'Directory completion did not open')
        assert(
            lua(
                [[local parent = ...; local items = vim.fn.complete_info().items
            return #items == 2 and vim.iter(items):all(function(item) return vim.startswith(item.word, parent) end)]],
                { base .. '/folder with spaces/child' }
            )
        )
        -- Picker-style navigation changes completion selection, not input history.
        for _, pair in ipairs { { '<Down>', '<Up>' }, { '<C-j>', '<C-k>' } } do
            local selected = lua [=[return vim.fn.complete_info().selected]=]
            input(pair[1])
            assert(lua('return vim.fn.pumvisible() == 1 and vim.fn.complete_info().selected == ...', { selected + 1 }))
            input(pair[2])
            assert(lua('return vim.fn.pumvisible() == 1 and vim.fn.complete_info().selected == ...', { selected }))
            assert(lua [=[return vim.bo.filetype == 'snacks_input' and vim.api.nvim_buf_line_count(0) == 1]=])
        end
        snapshot(case[1] .. '-folder-completion')
        input '<Esc>'
        assert(lua [=[return vim.bo.filetype == 'snacks_input' and vim.fn.pumvisible() == 0]=])
        input '<Tab>'
        input '<CR>'
        assert(lua [=[return vim.bo.filetype == 'snacks_input' and vim.fn.pumvisible() == 0]=])
        local completed = lua [=[return vim.api.nvim_get_current_line()]=]
        input '<CR>'
        wait(function() return lua('return require("config.sessions").owner() == vim.uv.fs_realpath(...)', { completed }) end, 'Completed folder did not open')
        lua([[Snacks.picker.get()[1]:close(); require('config.sessions').reset_to_starter(); vim.api.nvim_set_current_dir(...)]], { base })

        -- Empty and invalid inputs must not activate a workspace or change cwd.
        for _, path in ipairs { '', 'missing-folder', 'project/sample.txt' } do
            input 'o'
            input('<C-u>' .. path)
            input '<CR>'
            wait(function() return lua [=[return vim.bo.filetype == 'ministarter']=] end, 'Invalid input changed the dashboard')
            assert(lua('return require("config.sessions").owner() == nil and vim.fn.getcwd() == ...', { base }))
        end

        -- Relative paths with spaces open a new workspace and its file picker.
        input 'O'
        input '<C-u>folder with spaces'
        input '<CR>'
        wait(function() return lua('return require("config.sessions").owner() == ...', { base .. '/folder with spaces' }) end, 'Relative folder did not open')
        assert(lua [=[return Snacks.picker.get()[1].opts.source == 'files']=])
        lua [=[Snacks.picker.get()[1]:close(); require('config.sessions').reset_to_starter()]=]

        -- Exercise tilde expansion while keeping the picker inside test fixtures.
        local tilde_path = lua('return "~" .. vim.env.HOME:gsub("[^/]+", "..") .. ...', { base .. '/folder with spaces' })
        input 'o'
        input('<C-u>' .. tilde_path)
        input '<CR>'
        wait(function() return lua('return require("config.sessions").owner() == ...', { base .. '/folder with spaces' }) end, 'Tilde path did not expand')
        lua [=[Snacks.picker.get()[1]:close(); require('config.sessions').reset_to_starter()]=]

        lua([[require('config.sessions').open_directory(..., {picker=false}); vim.cmd.edit('sample.txt')]], { base .. '/project' })
        lua [=[require('config.sessions').reset_to_starter()]=]
        input 'O'
        input('<C-u>' .. base .. '/project')
        input '<CR>'
        wait(function() return lua [=[return vim.fn.expand('%:t') == 'sample.txt']=] end, 'Dialog did not restore the workspace')
        assert(lua [=[return vim.ui.input == _G.original_ui_input and vim.fn.maparg('o', 'n') == '' and vim.fn.maparg('O', 'n') == '']=])
        input ' e'
        wait(function() return lua [=[return vim.bo.filetype == 'minifiles']=] end, 'Mini.files did not open')
        lua [=[require('mini.files').close()]=]
        input 'v4l sr'
        wait(function() return lua [=[return vim.bo.filetype == 'grug-far']=] end, 'Replacement did not open')
        assert(lua [=[return table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),'\n'):find('hello',1,true) ~= nil]=])
        local width = lua [=[return vim.api.nvim_win_get_width(0)]=]
        assert(case[2] >= 120 and width < case[2] or case[2] < 120 and width == case[2])
        snapshot(case[1] .. '-replace')
        input '<Esc>'
        lua [=[require('grug-far').get_instance():close()]=]

        -- Real insert/select-mode input: snippet navigation takes priority, then tabout.
        lua [=[vim.cmd.enew(); vim.bo.filetype='lua']=]
        input 'i'
        lua [=[vim.snippet.expand('call(${1:first}, ${2:second})$0')]=]
        input 'one'
        input '<Tab>'
        input 'two'
        input '<Tab>'
        input '<Esc>'
        assert(lua [=[return vim.api.nvim_get_current_line() == 'call(one, two)']=], lua [=[return vim.api.nvim_get_current_line()]=])
        lua [=[vim.snippet.stop(); vim.api.nvim_buf_set_lines(0,0,-1,false,{'call()'}); vim.api.nvim_win_set_cursor(0,{1,5})]=]
        input 'i<Tab>'
        assert(lua [=[return vim.api.nvim_win_get_cursor(0)[2] == 6 and vim.api.nvim_get_current_line() == 'call()']=])
        input '<Esc>'
        lua [=[vim.cmd('bwipeout!')]=]
        if case[3] then
            -- Over SSH only yanks copy, and pasting reuses the last yank without querying the terminal.
            lua [=[vim.cmd.enew(); vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'alpha', 'beta', 'gamma', 'delta' })]=]
            input 'ggyyjp'
            assert(lua [=[return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '|') == 'alpha|beta|alpha|gamma|delta']=])
            input 'xjdd'
            assert(lua [=[return vim.fn.getreg('+') == 'alpha\n']=], lua [=[return vim.inspect(vim.fn.getreg('+'))]=])
            input 'ggjVpjVp'
            assert(lua [=[return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '|') == 'alpha|alpha|alpha|delta']=])
            assert(lua [=[return not vim.api.nvim_exec2('messages', { output = true }).output:find('is empty', 1, true)]=])
            lua [=[vim.cmd('bwipeout!')]=]
        end
        -- Alt+Shift+h reorders buffer tabs; the order survives reopening the workspace.
        lua([[local root = ...; vim.cmd.edit(root .. '/sample.txt'); vim.cmd.edit(root .. '/second.txt')]], { base .. '/project' })
        local function order()
            return lua [=[return vim.tbl_map(function(e) return vim.fs.basename(e.path) end, require('bufferline').get_elements().elements)]=]
        end
        wait(function() return vim.deep_equal(order(), { 'sample.txt', 'second.txt' }) end, 'Bufferline did not list both files: ' .. vim.inspect(order()))
        input '<M-H>'
        wait(function() return vim.deep_equal(order(), { 'second.txt', 'sample.txt' }) end, 'Alt+Shift+h did not move the buffer')
        lua [=[require('config.sessions').reset_to_starter(); require('config.sessions').restore_last()]=]
        wait(function() return vim.deep_equal(order(), { 'second.txt', 'sample.txt' }) end, 'Buffer order was not restored: ' .. vim.inspect(order()))
        -- Restore with ui2 attached; cancel the modified-buffer transition using real input.
        lua [=[vim.api.nvim_buf_set_lines(0,0,1,false,{'unsaved'}); vim.schedule(function() require('config.sessions').reset_to_starter() end)]=]
        input '<Esc>'
        wait(function() return not rpc('nvim_get_mode').blocking end, 'Confirmation did not cancel')
        assert(lua [=[return require('config.sessions').owner() ~= nil and vim.bo.modified]=])
        lua [=[vim.bo.modified=false; require('config.sessions').reset_to_starter(); require('config.sessions').restore_last()]=]
        assert(lua [=[return require('config.sessions').owner() ~= nil]=])
        snapshot(case[1] .. '-restored')
        lua [=[require('config.sessions').detach()]=]
        stop()
    end

    -- New host: plugins are present, but there are no Mason packages or user parsers.
    start('fresh', 80, false, true)
    lua [=[vim.cmd.enew(); vim.bo.filetype='typescript']=]
    assert(lua [=[return not vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()]]=])
    assert(lua [=[return #require('mason-registry').get_installed_package_names() == 0]=])
    assert(lua [=[return package.loaded['mason-lspconfig'] == nil]=])
    vim.wait(1500, function() return false end)
    assert(lua [=[return #require('mason-registry').get_installed_package_names() == 0]=])
    assert(lua [=[return #vim.fn.glob(vim.fn.stdpath('data') .. '/site/parser/*',true,true) == 0]=])
    stop()
end, debug.traceback)
stop()
if not ok then
    io.stderr:write(err .. '\nArtifacts: ' .. base .. '\n')
    vim.cmd 'cquit 1'
end
print('Attached UI, SSH, and fresh-host checks passed; screen captures: ' .. base)
vim.cmd 'qa!'

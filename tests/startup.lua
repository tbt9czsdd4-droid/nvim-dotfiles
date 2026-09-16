-- Full configuration checks. Every child uses temporary state and cache storage.
-- Run from the config directory: nvim --headless -u NONE -i NONE -l tests/startup.lua
local config = vim.fn.getcwd()
local base = vim.fn.tempname()
local state = base .. '/state'
vim.fn.mkdir(base .. '/folder/nested', 'p')
vim.fn.mkdir(base .. '/other', 'p')
local folder = base .. '/folder'
local nested = folder .. '/nested'
local afile, bfile, outside = folder .. '/a.txt', folder .. '/b.txt', base .. '/other/outside.txt'
vim.fn.writefile({ 'one' }, afile)
vim.fn.writefile({ 'two' }, bfile)
vim.fn.writefile({ 'outside' }, outside)
assert(vim.uv.fs_symlink(folder, base .. '/alias'))
local child
local function equal(actual, expected) assert(vim.deep_equal(actual, expected), 'Expected ' .. vim.inspect(expected) .. ', got ' .. vim.inspect(actual)) end
local function lua(code, args) return vim.rpcrequest(child, 'nvim_exec_lua', code, args or {}) end
local function start(args, prelude)
    local command = { 'nvim', '--embed', '--headless', '-i', 'NONE', '-u', config .. '/init.lua' }
    if prelude then vim.list_extend(command, { '--cmd', 'lua ' .. prelude }) end
    vim.list_extend(command, args or {})
    child = vim.fn.jobstart(command, {
        rpc = true,
        env = { XDG_STATE_HOME = state, XDG_CACHE_HOME = base .. '/cache', NVIM_LOG_FILE = base .. '/nvim.log' },
    })
    assert(child > 0)
    lua 'vim.o.columns = 120; vim.o.lines = 40'
    lua 'vim.wait(400, function() return false end, 20)'
    local messages = lua 'return vim.api.nvim_exec2("messages", {output=true}).output'
    assert(not messages:find 'Error' and not messages:find 'stack traceback', messages)
end
local function stop()
    pcall(lua, 'vim.cmd("qa!")')
    vim.fn.jobwait({ child }, 2000)
    child = nil
end
local ok, err = xpcall(function()
    start()
    equal(lua 'return require("config.sessions").owner()', vim.NIL)
    equal(lua 'return vim.bo.filetype', 'ministarter')
    local items = lua 'return vim.tbl_map(function(x) return x.name end, MiniStarter.content_to_items(MiniStarter.get_content()))'
    equal(#items, 6)
    assert(vim.tbl_contains(items, 'Open folder…'))
    assert(vim.tbl_contains(items, 'Recent files…'))
    stop()

    start { folder }
    equal(lua 'return require("config.sessions").owner()', folder)
    equal(lua 'return require("config.project").root()', folder)
    equal(lua 'return Snacks.picker.get()[1].opts.source', 'files')
    lua('local a, b = ...; Snacks.picker.get()[1]:close(); vim.cmd.edit(a); vim.cmd.vsplit(b)', { afile, bfile })
    equal(lua 'return #vim.tbl_filter(function(w) return vim.api.nvim_win_get_config(w).relative == "" end, vim.api.nvim_list_wins())', 2)
    -- Split-preserving deletion uses the configured mapping callback.
    lua 'vim.fn.maparg(" bd", "n", false, true).callback(); vim.wait(150, function() return false end)'
    equal(lua 'return #vim.tbl_filter(function(w) return vim.api.nvim_win_get_config(w).relative == "" end, vim.api.nvim_list_wins())', 2)
    lua('vim.cmd.edit(...)', { bfile })
    stop()

    start { folder }
    equal(lua 'return require("config.sessions").owner()', folder)
    equal(lua 'return #vim.tbl_filter(function(w) return vim.api.nvim_win_get_config(w).relative == "" end, vim.api.nvim_list_wins())', 2)
    assert(lua('return vim.fn.bufnr(...) > 0', { bfile }))
    -- Editing an outside file retains workspace roots; smart search filters it.
    lua(
        'vim.cmd.edit(...); vim.fn.maparg("  ", "n", false, true).callback(); vim.wait(150, function() return false end); vim.wait(250, function() return false end)',
        { outside }
    )
    equal(lua 'return Snacks.picker.get()[1].opts.cwd', folder)
    assert(lua 'return Snacks.picker.get()[1].opts.filter.cwd')
    assert(
        lua([[local p = Snacks.picker.get()[1]; for _, item in ipairs(p:items()) do if item.file == ... then return false end end; return true]], { outside })
    )
    lua 'Snacks.picker.get()[1]:close(); vim.fn.maparg(" sR", "n", false, true).callback(); vim.wait(150, function() return false end)'
    equal(lua 'return Snacks.picker.get()[1].opts.source', 'smart')
    lua 'Snacks.picker.get()[1]:close()'
    -- The custom buffer search reads unsaved text.
    lua 'vim.api.nvim_buf_set_lines(0,0,-1,false,{"UNSAVED_NEEDLE"}); vim.fn.maparg(" sB", "n", false, true).callback(); vim.wait(150, function() return false end); vim.wait(100, function() return false end)'
    assert(lua [[for _, item in ipairs(Snacks.picker.get()[1]:items()) do if item.line == 'UNSAVED_NEEDLE' then return true end end; return false]])
    lua 'Snacks.picker.get()[1]:close(); vim.bo.modified = false'
    -- Both folder shortcuts open the same picker; picker confirmation switches.
    lua 'vim.fn.maparg(" fp", "n", false, true).callback(); vim.wait(150, function() return false end)'
    equal(lua 'return Snacks.picker.get()[1].opts.title', 'Folders (<C-d> forget)')
    lua 'Snacks.picker.get()[1]:close(); vim.fn.maparg(" qS", "n", false, true).callback(); vim.wait(150, function() return false end)'
    equal(lua 'return Snacks.picker.get()[1].opts.title', 'Folders (<C-d> forget)')
    lua 'Snacks.picker.get()[1]:close()'
    -- Lualine keeps workspace state in every preset.
    for _, preset in ipairs { 'auto', 'nord-minimal', 'dracula-rounded', 'gruvbox-powerline', 'palenight-slanted', 'iceberg-quiet' } do
        equal(lua('vim.cmd("LualinePreview " .. ...); return require("lualine").get_config().sections.lualine_c[1]()', { preset }), 'folder')
    end
    -- Autoformat precedence: buffer override wins over global default.
    lua [[
        local captured
        local conform = require('conform')
        local setup = conform.setup
        conform.setup = function(opts) captured = opts end
        package.loaded['plugins.conform'] = nil
        require('plugins.conform')
        conform.setup = setup
        local f = captured.format_on_save
        vim.g.autoformat = false; vim.b.autoformat = nil; assert(f(0) == nil)
        vim.fn.maparg(' uF', 'n', false, true).callback(); vim.wait(150, function() return false end); assert(vim.b.autoformat == true and f(0))
        vim.g.autoformat = true; vim.b.autoformat = false; assert(f(0) == nil)
        vim.b.autoformat = nil; assert(f(0))
        vim.fn.maparg(' uF', 'n', false, true).callback(); vim.wait(150, function() return false end); assert(vim.b.autoformat == false and f(0) == nil)
    ]]
    local servers = lua 'return require("mason-lspconfig.settings").current'
    local expected = {
        'angularls',
        'bashls',
        'clangd',
        'docker_compose_language_service',
        'dockerls',
        'jsonls',
        'lua_ls',
        'markdown_oxide',
        'neocmake',
        'pyright',
        'ruff',
        'rust_analyzer',
        'stylua',
        'taplo',
        'texlab',
        'tinymist',
        'vtsls',
        'yamlls',
    }
    equal(servers.ensure_installed, expected)
    equal(servers.automatic_enable, expected)
    for _, server in ipairs(expected) do
        assert(lua('return vim.lsp.is_enabled(...)', { server }), server .. ' was not enabled')
    end
    lua 'require("config.sessions").detach()' -- Preserve the initial two-window fixture.
    equal(lua 'return require("lualine").get_config().sections.lualine_c[1]()', 'Standalone')
    stop()

    start { nested }
    equal(lua 'return require("config.sessions").owner()', nested)
    equal(lua 'return Snacks.picker.get()[1].opts.cwd', nested)
    stop()
    start { base .. '/alias' }
    equal(lua 'return require("config.sessions").owner()', folder)
    equal(lua 'return #vim.tbl_filter(function(w) return vim.api.nvim_win_get_config(w).relative == "" end, vim.api.nvim_list_wins())', 2)
    stop()
    for _, args in ipairs { { afile }, { afile, outside }, { folder, outside } } do
        start(args)
        equal(lua 'return require("config.sessions").owner()', vim.NIL)
        assert(not lua 'return require("persistence").active()')
        stop()
    end
    start()
    equal(lua 'return vim.bo.filetype', 'ministarter')
    equal(lua 'return require("config.sessions").folders()[1].root', folder)
    -- The numbered dashboard item goes through the shared folder entrypoint.
    lua 'MiniStarter.set_query("1"); vim.wait(100, function() return false end)'
    equal(lua 'return require("config.sessions").owner()', folder)
    lua('require("config.sessions").reset_to_starter(); require("config.sessions").open_file_detached(...)', { outside })
    equal(lua 'return require("config.sessions").owner()', vim.NIL)
    equal(lua 'return vim.fn.getcwd()', base .. '/other')
    equal(lua 'return require("config.project").root()', base .. '/other')
    stop()

    -- Both unavailable and failing experimental UIs leave a usable command line.
    for _, prelude in ipairs {
        "package.preload['vim._core.ui2'] = function() error('unavailable') end",
        "package.loaded['vim._core.ui2'] = { enable = function(opts) if opts.enable ~= false then error('initialization failed') end end }",
    } do
        start({}, prelude)
        equal(lua 'return vim.o.cmdheight', 1)
        equal(lua 'return vim.bo.filetype', 'ministarter')
        stop()
    end

    -- Pipe startup, including empty stdin, must never activate a workspace/dashboard.
    for i, content in ipairs { 'from stdin\n', '' } do
        local report = base .. '/stdin-' .. i .. '.json'
        local code = 'lua vim.defer_fn(function() vim.fn.writefile({vim.json.encode({owner=require("config.sessions").owner() or false, active=require("persistence").active(), ft=vim.bo.filetype, lines=vim.api.nvim_buf_get_lines(0,0,-1,false)})}, '
            .. string.format('%q', report)
            .. '); vim.cmd("qa!") end, 250)'
        local result = vim.system({ 'nvim', '--headless', '-i', 'NONE', '-u', config .. '/init.lua', '+' .. code, '-' }, {
            stdin = content,
            env = { XDG_STATE_HOME = state, XDG_CACHE_HOME = base .. '/cache', NVIM_LOG_FILE = base .. '/nvim.log' },
        }):wait(10000)
        equal(result.code, 0)
        local data = vim.json.decode(table.concat(vim.fn.readfile(report)))
        equal(data.owner, false)
        equal(data.active, false)
        assert(data.ft ~= 'ministarter')
        equal(data.lines, { i == 1 and 'from stdin' or '' })
    end
end, debug.traceback)
if child then stop() end
if not ok then
    io.stderr:write(err .. '\nArtifacts: ' .. base .. '\n')
    vim.cmd 'cquit 1'
else
    print 'Full startup and picker checks passed'
    vim.cmd 'qa!'
end

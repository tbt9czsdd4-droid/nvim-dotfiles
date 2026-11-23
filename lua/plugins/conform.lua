local conform = require 'conform'

local function autoformat_enabled(bufnr)
    local override = vim.b[bufnr].autoformat
    if override ~= nil then return override end
    return vim.g.autoformat == true
end

-- notify_on_error stays off so failures on save are quiet. A manual format
-- reports the runtime errors Conform would otherwise only log.
local function format()
    conform.format({ async = true }, function(err)
        if err and err:match "^Formatter '.-' error" then
            local lines = vim.split(vim.trim(err), '\n')
            vim.notify(table.concat(vim.list_slice(lines, 1, 8), '\n') .. '\nSee :ConformInfo for details', vim.log.levels.ERROR)
        end
    end)
end

local function notify_autoformat(scope, enabled) vim.notify(string.format('%s autoformat %s', scope, enabled and 'enabled' or 'disabled'), vim.log.levels.INFO) end

-- Names VSG configs go by (the same list Conform's built-in vsg formatter uses).
local VSG_CONFIG_NAMES = {
    'vsg_config.yaml',
    'vsg_config.yml',
    'vsg_config.json',
    'vsg.yaml',
    'vsg.yml',
    'vsg.json',
    '.vsg_config.yaml',
    '.vsg_config.yml',
    '.vsg_config.json',
    '.vsg.yaml',
    '.vsg.yml',
    '.vsg.json',
}
local VSG_TEMPLATE = vim.fs.joinpath(vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2)))), 'vsg', 'default.vsg.yaml')

-- The user-wide style, created from this checkout's template if it is missing.
-- An existing file is never overwritten.
local function vsg_global_config()
    local xdg = os.getenv 'XDG_CONFIG_HOME'
    local path = vim.fs.joinpath(xdg and xdg ~= '' and xdg or vim.fs.joinpath(vim.uv.os_homedir(), '.config'), 'vsg', '.vsg.yaml')
    if vim.uv.fs_stat(path) then return path end
    if not vim.uv.fs_stat(VSG_TEMPLATE) then return nil end
    pcall(vim.fn.mkdir, vim.fs.dirname(path), 'p')
    if vim.uv.fs_copyfile(VSG_TEMPLATE, path, { excl = true }) then
        vim.schedule(function() vim.notify('Created ' .. vim.fn.fnamemodify(path, ':~') .. ' from the bundled VSG style', vim.log.levels.INFO) end)
    end
    return vim.uv.fs_stat(path) and path or nil
end

-- The global style first, then the nearest project config on top of it.
local function vsg_configs(dirname)
    local configs = {}
    local global = vsg_global_config()
    if global then table.insert(configs, global) end
    local project = vim.fs.find(VSG_CONFIG_NAMES, { path = dirname, upward = true })[1]
    if project and not (global and vim.fn.resolve(project) == vim.fn.resolve(global)) then table.insert(configs, project) end
    return configs
end

conform.setup {
    notify_on_error = false,
    default_format_opts = {
        lsp_format = 'fallback',
    },
    format_on_save = function(bufnr)
        if not autoformat_enabled(bufnr) then return end
        -- VSG starts a Python interpreter and parses the whole file.
        return { timeout_ms = vim.bo[bufnr].filetype == 'vhdl' and 3000 or 500 }
    end,
    formatters_by_ft = {
        bash = { 'shfmt' },
        c = { 'clang_format' },
        vhdl = { 'vsg' },
        cpp = { 'clang_format' },
        lua = { 'stylua' },
        python = { 'ruff_format' },
        rust = { 'rustfmt' },
        sh = { 'shfmt' },
        javascript = { 'prettier' },
        javascriptreact = { 'prettier' },
        typescript = { 'prettier' },
        typescriptreact = { 'prettier' },
        html = { 'prettier' },
        css = { 'prettier' },
        scss = { 'prettier' },
        json = { 'prettier' },
        jsonc = { 'prettier' },
        yaml = { 'prettier' },
        markdown = { 'prettier' },
    },
    formatters = {
        shfmt = {
            prepend_args = { '-i', '4' },
        },
        vsg = {
            -- VSG writes its fixes and then exits 1 if violations it cannot
            -- fix remain. Config and parse errors also exit 1 but leave the
            -- file untouched, so accepting 1 never loses or corrupts text.
            exit_codes = { 0, 1 },
            args = function(_, ctx)
                local args = { '--fix', '-of', 'syntastic', '-f', '$FILENAME' }
                local configs = vsg_configs(ctx.dirname)
                if #configs > 0 then vim.list_extend(args, { '-c', unpack(configs) }) end
                return args
            end,
        },
    },
}

local map = vim.keymap.set
map({ 'n', 'x' }, '<leader>cf', format, { desc = 'Format' })
map('n', '<leader>uf', function()
    vim.g.autoformat = not vim.g.autoformat
    notify_autoformat('Global', vim.g.autoformat)
end, { desc = 'Toggle global autoformat' })
map('n', '<leader>uF', function()
    vim.b.autoformat = not autoformat_enabled(0)
    notify_autoformat('Buffer', vim.b.autoformat)
end, { desc = 'Toggle buffer autoformat' })

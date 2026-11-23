local conform = require 'conform'

local function autoformat_enabled(bufnr)
    local override = vim.b[bufnr].autoformat
    if override ~= nil then return override end
    return vim.g.autoformat == true
end

local function format()
    if vim.bo.filetype ~= 'vhdl' then return conform.format { async = true } end
    conform.format({ async = true, quiet = true }, function(err)
        if err then
            local reason = table.concat(vim.list_slice(vim.split(vim.trim(err), '\n'), 1, 3), '\n')
            vim.notify('VHDL format failed. ' .. reason .. '\nSee :ConformInfo for details.', vim.log.levels.ERROR)
        end
    end)
end

local function vsg_python()
    local vsg = vim.fn.exepath 'vsg'
    if vsg == '' then return 'vsg' end -- Let Conform report the missing executable.
    local python = vim.fs.joinpath(vim.fs.dirname(vim.fn.resolve(vsg)), 'python3')
    return vim.fn.executable(python) == 1 and python or 'python3'
end

local function notify_autoformat(scope, enabled) vim.notify(string.format('%s autoformat %s', scope, enabled and 'enabled' or 'disabled'), vim.log.levels.INFO) end

conform.setup {
    notify_on_error = false,
    default_format_opts = {
        lsp_format = 'fallback',
    },
    format_on_save = function(bufnr)
        if not autoformat_enabled(bufnr) then return end
        return { timeout_ms = 500 }
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
        vsg = {
            stdin = true,
            command = vsg_python,
            args = function(config, ctx)
                local args = require('conform.formatters.vsg').args(config, ctx)
                local index = vim.fn.index(args, '-c')
                local style = index >= 0 and args[index + 2] or vim.api.nvim_get_runtime_file('.vsg.yaml', false)[1]
                local adapter = vim.api.nvim_get_runtime_file('scripts/vsg_format.py', false)[1]
                return { adapter, vim.fn.exepath 'vsg', '$FILENAME', style }
            end,
        },
        shfmt = {
            prepend_args = { '-i', '4' },
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

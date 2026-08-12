local conform = require 'conform'

local function format()
    conform.format {
        async = true,
        lsp_format = 'fallback',
    }
end

local function notify_autoformat(scope, enabled) vim.notify(string.format('%s autoformat %s', scope, enabled and 'enabled' or 'disabled'), vim.log.levels.INFO) end

conform.setup {
    notify_on_error = false,
    default_format_opts = {
        lsp_format = 'fallback',
    },
    format_on_save = function(bufnr)
        if vim.g.autoformat == false or vim.b[bufnr].autoformat == false then return end
        return {
            timeout_ms = 500,
            lsp_format = 'fallback',
        }
    end,
    formatters_by_ft = {
        bash = { 'shfmt' },
        c = { 'clang_format' },
        cpp = { 'clang_format' },
        lua = { 'stylua' },
        python = { 'ruff_format' },
        rust = { 'rustfmt', lsp_format = 'fallback' },
        sh = { 'shfmt' },
    },
    formatters = {
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
    if vim.b.autoformat == nil then
        vim.b.autoformat = false
    else
        vim.b.autoformat = not vim.b.autoformat
    end
    notify_autoformat('Buffer', vim.b.autoformat)
end, { desc = 'Toggle buffer autoformat' })

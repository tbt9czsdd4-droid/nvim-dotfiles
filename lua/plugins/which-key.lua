local which_key = require 'which-key'

which_key.setup {
    preset = 'helix',
    delay = 300,
    spec = {
        {
            mode = { 'n', 'x' },
            { '<leader>b', group = 'buffer' },
            { '<leader>c', group = 'code' },
            { '<leader>d', group = 'debug' },
            { '<leader>f', group = 'file/find' },
            { '<leader>q', group = 'quit/session' },
            { '<leader>s', group = 'search' },
            { '<leader>u', group = 'ui/toggles' },
            { '<leader>x', group = 'diagnostics/quickfix' },
            { '[', group = 'previous' },
            { ']', group = 'next' },
            { 'g', group = 'goto' },
            { 'z', group = 'fold' },
        },
    },
}

vim.keymap.set('n', '<leader>?', function() which_key.show { global = false } end, { desc = 'Buffer-local keymaps' })

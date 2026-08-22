local project_root = require('config.project').root

require('snacks').setup {
    explorer = {
        enabled = true,
        replace_netrw = false,
    },
    indent = {
        enabled = true,
        char = '│',
    },
    scope = {
        enabled = true,
        char = '|',
        underline = false,
    },
    terminal = {
        win = {
            position = 'bottom',
            border = 'top',
            height = 0.3,
        },
    },
}

local map = vim.keymap.set

map('n', '<leader>ft', function() Snacks.terminal.toggle(nil, { cwd = project_root() }) end, { desc = 'Terminal (project root)' })
map('n', '<leader>fT', function() Snacks.terminal.toggle(nil, { cwd = vim.uv.cwd() }) end, { desc = 'Terminal (cwd)' })
map('n', '<leader>E', function() Snacks.explorer { cwd = project_root() } end, { desc = 'Explorer (project)' })

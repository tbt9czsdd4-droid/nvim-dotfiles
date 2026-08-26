local project_root = require('config.project').root

require('snacks').setup {
    explorer = {
        enabled = true,
        replace_netrw = false,
    },
    picker = {
        sources = {
            files = {
                hidden = true,
            },
        },
    },
    indent = {
        enabled = true,
        indent = {
            char = '│',
        },
        scope = {
            char = '|',
            underline = false,
        },
    },
    scope = {
        enabled = true,
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

local function pick_files(cwd) Snacks.picker.files { cwd = cwd } end
local function grep(cwd) Snacks.picker.grep { cwd = cwd } end

map('n', '<leader><space>', function() pick_files(project_root()) end, { desc = 'Find files (project)' })
map('n', '<leader>/', function() grep(project_root()) end, { desc = 'Grep project' })
map('n', '<leader>ff', function() pick_files(project_root()) end, { desc = 'Find files (project)' })
map('n', '<leader>fF', function() pick_files(vim.uv.cwd()) end, { desc = 'Find files (cwd)' })
map('n', '<leader>fc', function() pick_files(vim.fn.stdpath 'config') end, { desc = 'Find config file' })
map('n', '<leader>sg', function() grep(project_root()) end, { desc = 'Grep project' })
map('n', '<leader>sG', function() grep(vim.uv.cwd()) end, { desc = 'Grep cwd' })
map('n', '<leader>ft', function() Snacks.terminal.toggle(nil, { cwd = project_root() }) end, { desc = 'Terminal (project root)' })
map('n', '<leader>fT', function() Snacks.terminal.toggle(nil, { cwd = vim.uv.cwd() }) end, { desc = 'Terminal (cwd)' })
map('n', '<leader>E', function() Snacks.explorer { cwd = project_root() } end, { desc = 'Explorer (project)' })

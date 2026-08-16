local root_markers = {
    '.git',
    'Cargo.toml',
    'pyproject.toml',
    'CMakeLists.txt',
    'Makefile',
    'package.json',
}

local function project_root()
    local name = vim.api.nvim_buf_get_name(0)
    local start = name ~= '' and vim.fs.dirname(name) or vim.uv.cwd()
    return vim.fs.root(start, root_markers) or vim.uv.cwd()
end

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

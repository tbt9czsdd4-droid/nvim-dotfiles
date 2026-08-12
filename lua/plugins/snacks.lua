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

local function has_file_buffers()
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buffer].buftype == '' and vim.api.nvim_buf_get_name(buffer) ~= '' then return true end
    end

    return false
end

local function open_project(picker, item)
    picker:close()
    if not item then return end

    local persistence = require 'persistence'

    -- Preserve the project being left, but do not overwrite a session with
    -- the empty dashboard state.
    if has_file_buffers() then persistence.save() end

    vim.fn.chdir(item.file)

    local session = persistence.current()
    local branchless_session = persistence.current { branch = false }

    if vim.fn.filereadable(session) == 1 or vim.fn.filereadable(branchless_session) == 1 then
        persistence.load()
    else
        Snacks.picker.files { cwd = item.file }
    end
end

require('snacks').setup {
    explorer = {
        enabled = true,
        replace_netrw = true,
    },
    picker = {
        enabled = true,
        sources = {
            projects = {
                confirm = open_project,
            },
        },
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
map('n', '<leader><space>', function() Snacks.picker.files { cwd = project_root() } end, { desc = 'Find files (project)' })
map('n', '<leader>/', function() Snacks.picker.grep { cwd = project_root() } end, { desc = 'Grep project' })
map('n', '<leader>,', function() Snacks.picker.buffers() end, { desc = 'Buffers' })
map('n', '<leader>:', function() Snacks.picker.command_history() end, { desc = 'Command history' })
map('n', '<leader>E', function() Snacks.explorer { cwd = project_root() } end, { desc = 'Explorer (project)' })
map('n', '<leader>o', function() Snacks.picker.treesitter() end, { desc = 'Code outline' })
map('n', '<leader>ff', function() Snacks.picker.files { cwd = project_root() } end, { desc = 'Find files (project)' })
map('n', '<leader>fF', function() Snacks.picker.files() end, { desc = 'Find files (cwd)' })
map('n', '<leader>fg', function() Snacks.picker.git_files() end, { desc = 'Find Git files' })
map('n', '<leader>fr', function() Snacks.picker.recent { filter = { cwd = true } } end, { desc = 'Recent files (cwd)' })
map('n', '<leader>fR', function() Snacks.picker.recent() end, { desc = 'Recent files' })
map('n', '<leader>fp', function() Snacks.picker.projects() end, { desc = 'Projects' })
map('n', '<leader>fc', function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end, { desc = 'Find config file' })
map('n', '<leader>sb', function() Snacks.picker.lines() end, { desc = 'Buffer lines' })
map('n', '<leader>sB', function() Snacks.picker.grep_buffers() end, { desc = 'Grep open buffers' })
map('n', '<leader>sg', function() Snacks.picker.grep { cwd = project_root() } end, { desc = 'Grep project' })
map('n', '<leader>sG', function() Snacks.picker.grep() end, { desc = 'Grep cwd' })
map({ 'n', 'x' }, '<leader>sw', function() Snacks.picker.grep_word { cwd = project_root() } end, { desc = 'Search word/selection' })
map('n', '<leader>s"', function() Snacks.picker.registers() end, { desc = 'Registers' })
map('n', '<leader>sa', function() Snacks.picker.autocmds() end, { desc = 'Autocommands' })
map('n', '<leader>sc', function() Snacks.picker.command_history() end, { desc = 'Command history' })
map('n', '<leader>sC', function() Snacks.picker.commands() end, { desc = 'Commands' })
map('n', '<leader>sd', function() Snacks.picker.diagnostics() end, { desc = 'Diagnostics' })
map('n', '<leader>sD', function() Snacks.picker.diagnostics_buffer() end, { desc = 'Buffer diagnostics' })
map('n', '<leader>sh', function() Snacks.picker.help() end, { desc = 'Help pages' })
map('n', '<leader>sk', function() Snacks.picker.keymaps() end, { desc = 'Keymaps' })
map('n', '<leader>sm', function() Snacks.picker.marks() end, { desc = 'Marks' })
map('n', '<leader>su', function() Snacks.picker.undo() end, { desc = 'Undo history' })

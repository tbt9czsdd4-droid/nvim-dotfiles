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

local function pick_files(cwd) Snacks.picker.files { cwd = cwd } end
local function grep(cwd) Snacks.picker.grep { cwd = cwd } end

local function open_project(path)
    local result = require('config.sessions').open_directory(path)
    if result == 'created' or result == 'detached' then pick_files(path) end
end

local function projects()
    local visits = require 'mini.visits'
    local items = {}

    for cwd, paths in pairs(visits.get_index()) do
        local count, latest = 0, 0

        for _, data in pairs(paths) do
            count = count + data.count
            latest = math.max(latest, data.latest)
        end

        if vim.fn.isdirectory(cwd) == 1 then
            table.insert(items, {
                path = cwd,
                file = cwd,
                dir = true,
                text = vim.fn.fnamemodify(cwd, ':p:~'),
                count = count,
                latest = latest,
            })
        end
    end

    items = visits.gen_sort.default()(items)
    Snacks.picker.pick {
        title = 'Projects',
        items = items,
        format = 'text',
        show_empty = true,
        confirm = function(picker, item)
            picker:close()
            if not item then return end
            vim.schedule(function() open_project(item.path) end)
        end,
    }
end

local function selection_or_word()
    local mode = vim.fn.mode()
    if mode == 'v' or mode == 'V' or mode == '\22' then
        return vim.trim(table.concat(vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', { type = mode }), '\n'))
    end

    return vim.fn.expand '<cword>'
end

local function grep_selection()
    Snacks.picker.grep {
        cwd = project_root(),
        regex = false,
        search = selection_or_word(),
    }
end

local function buffer_lines()
    Snacks.picker.pick {
        title = 'Grep open buffers',
        finder = function()
            local items = {}

            for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
                if vim.bo[buffer].buflisted and vim.bo[buffer].buftype == '' then
                    vim.fn.bufload(buffer)
                    local file = vim.api.nvim_buf_get_name(buffer)

                    for line_number, line in ipairs(vim.api.nvim_buf_get_lines(buffer, 0, -1, false)) do
                        table.insert(items, {
                            buf = buffer,
                            file = file,
                            line = line,
                            pos = { line_number, 0 },
                            text = file .. ' ' .. line,
                        })
                    end
                end
            end

            return items
        end,
        format = 'file',
        show_empty = true,
    }
end

map('n', '<leader><space>', function() pick_files(project_root()) end, { desc = 'Find files (project)' })
map('n', '<leader>/', function() grep(project_root()) end, { desc = 'Grep project' })
map('n', '<leader>,', function() Snacks.picker.buffers() end, { desc = 'Buffers' })
map('n', '<leader>:', function() Snacks.picker.command_history() end, { desc = 'Command history' })
map('n', '<leader>ff', function() pick_files(project_root()) end, { desc = 'Find files (project)' })
map('n', '<leader>fF', function() pick_files(vim.uv.cwd()) end, { desc = 'Find files (cwd)' })
map('n', '<leader>fc', function() pick_files(vim.fn.stdpath 'config') end, { desc = 'Find config file' })
map('n', '<leader>fg', function() Snacks.picker.git_files() end, { desc = 'Find Git files' })
map('n', '<leader>fr', function() Snacks.picker.recent { filter = { cwd = true, paths = false } } end, { desc = 'Recent files (cwd)' })
map('n', '<leader>fR', function() Snacks.picker.recent { filter = false } end, { desc = 'Recent files' })
map('n', '<leader>fp', projects, { desc = 'Projects' })
map('n', '<leader>sg', function() grep(project_root()) end, { desc = 'Grep project' })
map('n', '<leader>sG', function() grep(vim.uv.cwd()) end, { desc = 'Grep cwd' })
map('n', '<leader>sb', function() Snacks.picker.lines() end, { desc = 'Buffer lines' })
map('n', '<leader>sB', buffer_lines, { desc = 'Grep open buffers' })
map({ 'n', 'x' }, '<leader>sw', grep_selection, { desc = 'Search word/selection' })
map('n', '<leader>s"', function() Snacks.picker.registers() end, { desc = 'Registers' })
map('n', '<leader>sa', function() Snacks.picker.autocmds() end, { desc = 'Autocommands' })
map('n', '<leader>sc', function() Snacks.picker.command_history() end, { desc = 'Command history' })
map('n', '<leader>sC', function() Snacks.picker.commands() end, { desc = 'Commands' })
map('n', '<leader>sd', function() Snacks.picker.diagnostics { filter = { cwd = false } } end, { desc = 'Diagnostics' })
map('n', '<leader>sD', function() Snacks.picker.diagnostics_buffer() end, { desc = 'Buffer diagnostics' })
map('n', '<leader>sh', function() Snacks.picker.help() end, { desc = 'Help pages' })
map('n', '<leader>sk', function() Snacks.picker.keymaps() end, { desc = 'Keymaps' })
map('n', '<leader>sm', function() Snacks.picker.marks() end, { desc = 'Marks' })
map('n', '<leader>su', function() Snacks.picker.undo() end, { desc = 'Undo history' })
map('n', '<leader>?', function() Snacks.picker.keymaps { global = false } end, { desc = 'Buffer-local keymaps' })
map('n', '<leader>ft', function() Snacks.terminal.toggle(nil, { cwd = project_root() }) end, { desc = 'Terminal (project root)' })
map('n', '<leader>fT', function() Snacks.terminal.toggle(nil, { cwd = vim.uv.cwd() }) end, { desc = 'Terminal (cwd)' })
map('n', '<leader>E', function() Snacks.explorer { cwd = project_root() } end, { desc = 'Explorer (project)' })

local icons = require 'mini.icons'
icons.setup {
    style = vim.g.have_nerd_font and 'glyph' or 'ascii',
}
icons.mock_nvim_web_devicons()

require('mini.pairs').setup {
    modes = {
        insert = true,
        command = true,
        terminal = false,
    },
}

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

require('mini.files').setup {
    options = {
        use_as_default_explorer = true,
    },
    windows = {
        preview = true,
        width_focus = 30,
        width_nofocus = 15,
        width_preview = 50,
    },
}

vim.keymap.set('n', '<leader>e', function()
    local path = vim.api.nvim_buf_get_name(0)
    local MiniFiles = require 'mini.files'

    if path == '' then path = vim.uv.cwd() end
    MiniFiles.open(path, false)
end, { desc = 'Open mini.files' })

local pick = require 'mini.pick'
local extra = require 'mini.extra'
local visits = require 'mini.visits'

pick.setup {
    mappings = {
        move_down = '<C-j>',
        move_up = '<C-k>',
    },
    window = {
        config = function()
            local height = math.floor(0.618 * vim.o.lines)
            local width = math.floor(0.618 * vim.o.columns)

            return {
                anchor = 'NW',
                height = height,
                width = width,
                row = math.floor(0.5 * (vim.o.lines - height)),
                col = math.floor(0.5 * (vim.o.columns - width)),
            }
        end,
    },
}
extra.setup()
visits.setup()

local function show_files(buf_id, items, query) pick.default_show(buf_id, items, query, { show_icons = true }) end

local function pick_files(cwd)
    return pick.builtin.cli({
        command = { 'rg', '--files', '--hidden', '--glob', '!.git', '--color=never' },
    }, {
        source = {
            cwd = cwd,
            name = 'Files (rg, hidden)',
            show = show_files,
        },
    })
end

-- Make `:Pick files` use the same hidden-file-aware picker as the keymaps.
pick.registry.files = function() return pick_files(vim.uv.cwd()) end

local function grep_live(cwd) pick.builtin.grep_live(nil, { source = { cwd = cwd } }) end

local function open_project(path)
    local result = require('config.sessions').open_directory(path)
    if result == 'created' or result == 'detached' then pick_files(path) end
end

pick.registry.projects = function()
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
                text = vim.fn.fnamemodify(cwd, ':p:~'),
                count = count,
                latest = latest,
            })
        end
    end

    items = visits.gen_sort.default()(items)
    pick.start {
        source = {
            items = items,
            name = 'Projects',
            choose = function(item)
                vim.schedule(function() open_project(item.path) end)
            end,
        },
    }
end

pick.registry.autocommands = function()
    local items = vim.tbl_map(function(autocmd)
        local action = autocmd.desc or autocmd.command or tostring(autocmd.callback or '')
        autocmd.text = string.format('%s  %s  %s', autocmd.event, autocmd.pattern, action)
        return autocmd
    end, vim.api.nvim_get_autocmds {})

    pick.start {
        source = {
            items = items,
            name = 'Autocommands',
            choose = function() end,
        },
    }
end

pick.registry.undo = function()
    local buffer = vim.api.nvim_get_current_buf()
    local tree = vim.fn.undotree()
    local items = {}

    local function add_entries(entries)
        for _, entry in ipairs(entries or {}) do
            table.insert(items, {
                seq = entry.seq,
                time = entry.time,
                text = string.format('%d  %s', entry.seq, os.date('%Y-%m-%d %H:%M:%S', entry.time)),
            })
            add_entries(entry.alt)
        end
    end

    add_entries(tree.entries)
    table.sort(items, function(a, b) return a.seq > b.seq end)

    pick.start {
        source = {
            items = items,
            name = 'Undo history',
            choose = function(item)
                vim.api.nvim_buf_call(buffer, function() vim.cmd('undo ' .. item.seq) end)
            end,
        },
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
    local query = selection_or_word()
    vim.schedule(function()
        if pick.is_picker_active() then pick.set_picker_query(vim.fn.split(query, '\\zs')) end
    end)
    pick.builtin.grep_live({ method = 'plain' }, { source = { cwd = project_root() } })
end

local map = vim.keymap.set

map('n', '<leader><space>', function() pick_files(project_root()) end, { desc = 'Find files (project)' })
map('n', '<leader>/', function() grep_live(project_root()) end, { desc = 'Grep project' })
map('n', '<leader>,', pick.builtin.buffers, { desc = 'Buffers' })
map('n', '<leader>:', function() extra.pickers.history { scope = ':' } end, { desc = 'Command history' })
map('n', '<leader>ff', function() pick_files(project_root()) end, { desc = 'Find files (project)' })
map('n', '<leader>fF', function() pick_files(vim.uv.cwd()) end, { desc = 'Find files (cwd)' })
map('n', '<leader>fg', extra.pickers.git_files, { desc = 'Find Git files' })
map('n', '<leader>fr', function() extra.pickers.oldfiles { current_dir = true } end, { desc = 'Recent files (cwd)' })
map('n', '<leader>fR', extra.pickers.oldfiles, { desc = 'Recent files' })
map('n', '<leader>fp', pick.registry.projects, { desc = 'Projects' })
map('n', '<leader>fc', function() pick_files(vim.fn.stdpath 'config') end, { desc = 'Find config file' })
map('n', '<leader>sb', function() extra.pickers.buf_lines { scope = 'current' } end, { desc = 'Buffer lines' })
map('n', '<leader>sB', function() extra.pickers.buf_lines { scope = 'all' } end, { desc = 'Grep open buffers' })
map('n', '<leader>sg', function() grep_live(project_root()) end, { desc = 'Grep project' })
map('n', '<leader>sG', function() grep_live(vim.uv.cwd()) end, { desc = 'Grep cwd' })
map({ 'n', 'x' }, '<leader>sw', grep_selection, { desc = 'Search word/selection' })
map('n', '<leader>s"', extra.pickers.registers, { desc = 'Registers' })
map('n', '<leader>sa', pick.registry.autocommands, { desc = 'Autocommands' })
map('n', '<leader>sc', function() extra.pickers.history { scope = ':' } end, { desc = 'Command history' })
map('n', '<leader>sC', extra.pickers.commands, { desc = 'Commands' })
map('n', '<leader>sd', function() extra.pickers.diagnostic { scope = 'all' } end, { desc = 'Diagnostics' })
map('n', '<leader>sD', function() extra.pickers.diagnostic { scope = 'current' } end, { desc = 'Buffer diagnostics' })
map('n', '<leader>sh', pick.builtin.help, { desc = 'Help pages' })
map('n', '<leader>sk', extra.pickers.keymaps, { desc = 'Keymaps' })
map('n', '<leader>sm', extra.pickers.marks, { desc = 'Marks' })
map('n', '<leader>su', pick.registry.undo, { desc = 'Undo history' })
map('n', '<leader>?', function() extra.pickers.keymaps { scope = 'buf' } end, { desc = 'Buffer-local keymaps' })

local clue = require 'mini.clue'
clue.setup {
    triggers = {
        { mode = { 'n', 'x' }, keys = '<Leader>' },
        { mode = { 'n', 'x' }, keys = '[' },
        { mode = { 'n', 'x' }, keys = ']' },
        { mode = { 'n', 'x' }, keys = 'g' },
        { mode = { 'n', 'x' }, keys = 'z' },
    },
    clues = {
        { mode = { 'n', 'x' }, keys = '<Leader>b', desc = '+buffer' },
        { mode = { 'n', 'x' }, keys = '<Leader>c', desc = '+code' },
        { mode = { 'n', 'x' }, keys = '<Leader>d', desc = '+debug' },
        { mode = { 'n', 'x' }, keys = '<Leader>f', desc = '+file/find' },
        { mode = { 'n', 'x' }, keys = '<Leader>q', desc = '+quit/session' },
        { mode = { 'n', 'x' }, keys = '<Leader>s', desc = '+search' },
        { mode = { 'n', 'x' }, keys = '<Leader>u', desc = '+ui/toggles' },
        { mode = { 'n', 'x' }, keys = '<Leader>x', desc = '+diagnostics/quickfix' },
        clue.gen_clues.square_brackets(),
        clue.gen_clues.g(),
        clue.gen_clues.z(),
    },
    window = {
        delay = 300,
    },
}

require('mini.move').setup {
    mappings = {
        left = '<M-h>',
        right = '<M-l>',
        down = '<M-j>',
        up = '<M-k>',
        line_left = '<M-h>',
        line_right = '<M-l>',
        line_down = '<M-j>',
        line_up = '<M-k>',
    },
}

local animate = require 'mini.animate'
animate.setup {
    cursor = {
        enable = true,
        timing = animate.gen_timing.linear { duration = 100, unit = 'total' },
    },
    scroll = {
        enable = true,
        timing = animate.gen_timing.linear { duration = 100, unit = 'total' },
    },
    -- Keep this disabled. It previously triggered the WezTerm resize/statusline bug.
    resize = {
        enable = false,
    },
    open = {
        enable = true,
        timing = animate.gen_timing.linear { duration = 100, unit = 'total' },
    },
    close = {
        enable = true,
        timing = animate.gen_timing.linear { duration = 100, unit = 'total' },
    },
}

local starter = require 'mini.starter'
local pick = require 'mini.pick'
local pickers = require('mini.extra').pickers

local function clean_dead_sessions()
    local persistence = require 'persistence'

    for _, session in ipairs(persistence.list()) do
        local filename = vim.fn.fnamemodify(session, ':t:r')

        -- Remove optional branch suffix
        local dir = vim.split(filename, '%%', { plain = true })[1]

        -- Persistence encodes path separators as %
        dir = dir:gsub('%%', '/')

        if vim.uv.fs_stat(dir) == nil then vim.fn.delete(session) end
    end
end

local function select_session()
    clean_dead_sessions()
    require('persistence').select()
end

starter.setup {
    evaluate_single = true,

    header = [[
███╗   ██╗██╗   ██╗██╗███╗   ███╗
████╗  ██║██║   ██║██║████╗ ████║
██╔██╗ ██║██║   ██║██║██╔████╔██║
██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
]],

    items = {
        {
            name = 'Sessions',
            section = 'Open',
            action = select_session,
        },
        {
            name = 'Projects',
            section = 'Open',
            action = pick.registry.projects,
        },
        {
            name = 'Files',
            section = 'Open',
            action = pickers.oldfiles,
        },
        {
            name = 'Config',
            section = 'Config',
            action = function()
                vim.cmd.cd(vim.fn.stdpath 'config')
                pick.registry.files()
            end,
        },
        {
            name = 'Update Plugins',
            section = 'Config',
            action = function() vim.pack.update() end,
        },
        {
            name = 'Quit',
            section = 'Builtin',
            action = 'qall',
        },
    },

    footer = 'Type an item prefix or use ↑/↓ and Enter',
    content_hooks = {
        starter.gen_hook.adding_bullet(),
        -- starter.gen_hook.indexing 'all',
        starter.gen_hook.aligning('center', 'center'),
    },
}

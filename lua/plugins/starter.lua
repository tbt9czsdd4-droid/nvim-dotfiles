local starter = require 'mini.starter'
local pick = require 'mini.pick'
local pickers = require('mini.extra').pickers

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
            name = 'Workspaces',
            section = 'Open',
            action = function() require('persistence').select() end,
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
                pick.builtin.files()
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

local starter = require 'mini.starter'
local sessions = require 'config.sessions'

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
            action = sessions.select,
        },
        {
            name = 'Files',
            section = 'Open',
            action = sessions.recent_files,
        },
        {
            name = 'Config',
            section = 'Config',
            action = function()
                local config = vim.fn.stdpath 'config'
                vim.cmd.cd(config)
                Snacks.picker.files { cwd = config }
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

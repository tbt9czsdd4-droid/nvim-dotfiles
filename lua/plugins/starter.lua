local starter = require 'mini.starter'
local sessions = require 'config.sessions'

starter.setup {
    autoopen = false, -- config.sessions distinguishes empty stdin from no arguments.
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
        function()
            local items = {}
            for i, folder in ipairs(sessions.folders { existing = true, limit = 6 }) do
                items[#items + 1] = {
                    name = i .. '  ' .. vim.fn.fnamemodify(folder.root, ':~'),
                    section = 'Recent folders',
                    action = function() sessions.open_directory(folder.root) end,
                }
            end
            return items
        end,
        { name = 'Open folder…', section = 'Actions', action = sessions.prompt_directory },
        { name = 'All folders…', section = 'Actions', action = sessions.select },
        { name = 'Recent files…', section = 'Actions', action = sessions.recent_files },
        { name = 'Config', section = 'Actions', action = function() sessions.open_directory(vim.fn.stdpath 'config') end },
        { name = 'Update plugins', section = 'Actions', action = function() vim.pack.update() end },
        { name = 'Quit', section = 'Actions', action = 'qall' },
    },

    footer = 'Type an item prefix or use ↑/↓ and Enter',
    content_hooks = {
        starter.gen_hook.adding_bullet(),
        starter.gen_hook.aligning('center', 'center'),
    },
}

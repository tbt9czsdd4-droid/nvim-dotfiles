return {
  {
    'nvim-mini/mini.starter',
    version = false,
    event = 'VimEnter',

    config = function()
      local starter = require 'mini.starter'

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
            name = 'Recent',
            section = 'Open',
            action = function() Snacks.picker.recent() end,
          },
          {
            name = 'Projects',
            section = 'Open',
            action = function() Snacks.picker.projects() end,
          },

          {
            name = 'Files',
            section = 'Open',
            action = function() Snacks.picker.files() end,
          },
          -- {
          --   name = 'Directories',
          --   section = 'Open',
          --   action = function() require('mini.files').open(nil, false) end,
          -- },
          {
            name = 'Config',
            section = 'Config',
            action = function()
              vim.cmd.cd(vim.fn.stdpath 'config')
              Snacks.picker.files()
            end,
          },
          {
            name = 'Lazy',
            section = 'Config',
            action = 'Lazy',
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
    end,
  },
}

return {
  {
    'folke/persistence.nvim',

    -- Persistence is tiny, and loading it immediately ensures that
    -- Snacks Projects can access it even from an empty startup screen.
    lazy = false,

    opts = {},

    keys = {
      {
        '<leader>qs',
        function() require('persistence').load() end,
        desc = 'Restore session',
      },
      {
        '<leader>qS',
        function() require('persistence').select() end,
        desc = 'Select session',
      },
      {
        '<leader>ql',
        function() require('persistence').load { last = true } end,
        desc = 'Restore last session',
      },
      {
        '<leader>qd',
        function() require('persistence').stop() end,
        desc = "Don't save current session",
      },
    },
  },
}

local sessions = require 'config.sessions'
sessions.setup()

local map = vim.keymap.set

map('n', '<leader>qs', sessions.restore_current, { desc = 'Restore session' })
map('n', '<leader>qS', sessions.select, { desc = 'Select session' })
map('n', '<leader>ql', sessions.restore_last, { desc = 'Restore last session' })
map('n', '<leader>qd', sessions.detach, { desc = "Don't save current session" })

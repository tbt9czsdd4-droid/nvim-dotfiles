local sessions = require 'config.sessions'
sessions.setup()

local map = vim.keymap.set

map('n', '<leader>qs', sessions.restore_current, { desc = 'Restore current folder' })
map('n', '<leader>qS', sessions.select, { desc = 'All folders' })
map('n', '<leader>ql', sessions.restore_last, { desc = 'Open most recent folder' })
map('n', '<leader>qd', sessions.detach, { desc = "Don't save current session" })
map('n', '<leader>qD', sessions.delete_current, { desc = 'Delete current session' })

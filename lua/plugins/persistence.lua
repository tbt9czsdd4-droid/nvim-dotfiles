require('persistence').setup {}

local map = vim.keymap.set

map('n', '<leader>qs', function() require('persistence').load() end, { desc = 'Restore session' })
map('n', '<leader>qS', function() require('persistence').select() end, { desc = 'Select session' })
map('n', '<leader>ql', function() require('persistence').load { last = true } end, { desc = 'Restore last session' })
map('n', '<leader>qd', function() require('persistence').stop() end, { desc = "Don't save current session" })

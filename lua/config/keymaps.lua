local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight' })

map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", {
    expr = true,
    silent = true,
    desc = 'Down',
})
map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", {
    expr = true,
    silent = true,
    desc = 'Up',
})

map('n', '<C-h>', '<C-w>h', { desc = 'Focus left window' })
map('n', '<C-j>', '<C-w>j', { desc = 'Focus lower window' })
map('n', '<C-k>', '<C-w>k', { desc = 'Focus upper window' })
map('n', '<C-l>', '<C-w>l', { desc = 'Focus right window' })

map('n', '<C-h>', '<C-w>h', { desc = 'Focus left window' })
map('n', '<C-Down>', '<cmd>resize -2<cr>', { desc = 'jrhejrhejk' })
map('n', '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease window width' })
map('n', '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase window width' })

map('n', '<leader>bb', '<cmd>buffer #<cr>', { desc = 'Other buffer' })
map('n', '<leader>bd', '<cmd>bdelete<cr>', { desc = 'Delete buffer' })

map({ 'n', 'i', 'x', 's' }, '<C-s>', '<cmd>write<cr><Esc>', { desc = 'Save file' })
map('n', '<leader>qq', '<cmd>qa<cr>', { desc = 'Quit all' })
map('n', '<leader>qx', '<cmd>restart lua require("config.sessions").reset_to_starter()<cr>', { desc = 'Restart Neovim' })

map('n', '[d', function() vim.diagnostic.jump { count = -1, float = true } end, { desc = 'Previous diagnostic' })

map('n', ']d', function() vim.diagnostic.jump { count = 1, float = true } end, { desc = 'Next diagnostic' })

map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line diagnostics' })

map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

map('t', '<C-h>', [[<C-\><C-n><C-w>h]], {
    desc = 'Go to left window',
})

map('t', '<C-j>', [[<C-\><C-n><C-w>j]], {
    desc = 'Go to lower window',
})

map('t', '<C-k>', [[<C-\><C-n><C-w>k]], {
    desc = 'Go to upper window',
})

map('t', '<C-l>', [[<C-\><C-n><C-w>l]], {
    desc = 'Go to right window',
})

-- Delete without overwriting registers
map({ 'n', 'x' }, 'd', '"_d', {
    desc = 'Delete without yanking',
})

-- Change without overwriting registers
map({ 'n', 'x' }, 'c', '"_c', {
    desc = 'Change without yanking',
})

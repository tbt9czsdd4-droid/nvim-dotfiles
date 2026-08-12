local flash = require 'flash'
flash.setup {}

local map = vim.keymap.set
map({ 'n', 'x', 'o' }, 's', function() flash.jump() end, { desc = 'Flash' })
map({ 'n', 'x', 'o' }, 'S', function() flash.treesitter() end, { desc = 'Flash Treesitter' })
map('o', 'r', function() flash.remote() end, { desc = 'Remote Flash' })
map({ 'o', 'x' }, 'R', function() flash.treesitter_search() end, { desc = 'Treesitter search' })
map('c', '<C-s>', function() flash.toggle() end, { desc = 'Toggle Flash search' })
map(
  { 'n', 'o', 'x' },
  '<C-Space>',
  function()
    flash.treesitter {
      actions = {
        ['<C-Space>'] = 'next',
        ['<BS>'] = 'prev',
      },
    }
  end,
  { desc = 'Treesitter incremental selection' }
)

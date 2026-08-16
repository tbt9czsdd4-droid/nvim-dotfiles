require('yanky').setup {
    ring = {
        history_length = 100,
    },
    highlight = {
        on_put = true,
        on_yank = true,
        timer = 300,
    },
    preserve_cursor_position = {
        enabled = true,
    },
}

local map = vim.keymap.set
map({ 'n', 'x' }, '<leader>p', function() require('yanky.picker').select_in_history() end, { desc = 'Yank history' })
map({ 'n', 'x' }, 'y', '<Plug>(YankyYank)', { desc = 'Yank text' })
map({ 'n', 'x' }, 'p', '<Plug>(YankyPutAfter)', { desc = 'Put after' })
map({ 'n', 'x' }, 'P', '<Plug>(YankyPutBefore)', { desc = 'Put before' })
map({ 'n', 'x' }, 'gp', '<Plug>(YankyGPutAfter)', { desc = 'Put after and move cursor' })
map({ 'n', 'x' }, 'gP', '<Plug>(YankyGPutBefore)', { desc = 'Put before and move cursor' })
map('n', '<C-p>', '<Plug>(YankyPreviousEntry)', { desc = 'Previous yank entry' })
map('n', '<C-n>', '<Plug>(YankyNextEntry)', { desc = 'Next yank entry' })
map('n', ']p', '<Plug>(YankyPutIndentAfterLinewise)', { desc = 'Put indented after' })
map('n', '[p', '<Plug>(YankyPutIndentBeforeLinewise)', { desc = 'Put indented before' })
map('n', ']P', '<Plug>(YankyPutIndentAfterLinewise)', { desc = 'Put indented after' })
map('n', '[P', '<Plug>(YankyPutIndentBeforeLinewise)', { desc = 'Put indented before' })
map('n', '>p', '<Plug>(YankyPutIndentAfterShiftRight)', { desc = 'Put and indent right' })
map('n', '<p', '<Plug>(YankyPutIndentAfterShiftLeft)', { desc = 'Put and indent left' })

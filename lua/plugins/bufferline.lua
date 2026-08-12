require('bufferline').setup {
    options = {
        mode = 'buffers',
        close_command = function(buffer_number) Snacks.bufdelete(buffer_number) end,
        right_mouse_command = function(buffer_number) Snacks.bufdelete(buffer_number) end,
        diagnostics = 'nvim_lsp',
        diagnostics_indicator = function(_, _, diagnostics)
            local result = ''
            if diagnostics.error then result = result .. '  ' .. diagnostics.error end
            if diagnostics.warning then result = result .. '  ' .. diagnostics.warning end
            return result
        end,
        always_show_bufferline = false,
        show_buffer_icons = true,
        show_buffer_close_icons = false,
        show_close_icon = false,
        separator_style = 'thin',
        offsets = {
            {
                filetype = 'snacks_layout_box',
            },
        },
    },
}

local map = vim.keymap.set
map('n', '<S-h>', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Previous buffer' })
map('n', '<S-l>', '<cmd>BufferLineCycleNext<cr>', { desc = 'Next buffer' })
map('n', '[b', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Previous buffer' })
map('n', ']b', '<cmd>BufferLineCycleNext<cr>', { desc = 'Next buffer' })
map('n', '[B', '<cmd>BufferLineMovePrev<cr>', { desc = 'Move buffer left' })
map('n', ']B', '<cmd>BufferLineMoveNext<cr>', { desc = 'Move buffer right' })
map('n', '<leader>bp', '<cmd>BufferLineTogglePin<cr>', { desc = 'Toggle buffer pin' })
map('n', '<leader>bP', '<cmd>BufferLineGroupClose ungrouped<cr>', { desc = 'Delete non-pinned buffers' })
map('n', '<leader>br', '<cmd>BufferLineCloseRight<cr>', { desc = 'Delete buffers to the right' })
map('n', '<leader>bl', '<cmd>BufferLineCloseLeft<cr>', { desc = 'Delete buffers to the left' })
map('n', '<leader>bj', '<cmd>BufferLinePick<cr>', { desc = 'Pick buffer' })

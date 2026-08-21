require('aerial').setup {
    layout = {
        default_direction = 'right',
        placement = 'window',
        win_opts = {
            statuscolumn = ' ',
        },
    },
}

local number_group = vim.api.nvim_create_augroup('aerial-focus-numbers', { clear = true })

vim.api.nvim_create_autocmd({ 'WinEnter', 'WinLeave' }, {
    group = number_group,
    callback = function(event)
        if vim.bo[event.buf].filetype ~= 'aerial' then return end

        local focused = event.event == 'WinEnter'
        vim.wo.number = false
        vim.wo.relativenumber = focused
        vim.wo.statuscolumn = focused and '%=%{v:relnum}   ' or ' '
    end,
    desc = 'Show relative numbers only while the Aerial window is focused',
})

vim.keymap.set('n', '<leader>o', '<cmd>AerialToggle! right<cr>', { desc = 'Toggle code outline' })

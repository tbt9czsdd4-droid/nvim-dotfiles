local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

local function set_line_number_highlight()
    vim.api.nvim_set_hl(0, 'CursorLineNr', {
        fg = '#ff9e64',
        bg = '#2a2e36',
        bold = true,
    })
end

autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
    group = augroup('kickstart-checktime', { clear = true }),
    callback = function()
        if vim.o.buftype ~= 'nofile' then vim.cmd 'checktime' end
    end,
})

autocmd('BufReadPost', {
    group = augroup('kickstart-last-location', { clear = true }),
    callback = function(event)
        local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
        local line_count = vim.api.nvim_buf_line_count(event.buf)
        if mark[1] > 0 and mark[1] <= line_count then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
    end,
})
set_line_number_highlight()

vim.api.nvim_create_autocmd('ColorScheme', {
    callback = set_line_number_highlight,
})

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

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

-- Flash yanked text and keep the cursor where the yank started (see `y` in keymaps.lua).
local yank = augroup('yank-feedback', { clear = true })
autocmd('TextYankPost', {
    group = yank,
    callback = function()
        vim.hl.on_yank { timeout = 300 }
        local cursor = vim.w.yank_cursor
        vim.w.yank_cursor = nil
        if cursor and vim.v.event.operator == 'y' then pcall(vim.api.nvim_win_set_cursor, 0, cursor) end
    end,
})
-- A cancelled yank (`y<Esc>`) must not move the cursor on a later one.
autocmd('ModeChanged', {
    group = yank,
    pattern = 'no*:*',
    callback = function() vim.w.yank_cursor = nil end,
})

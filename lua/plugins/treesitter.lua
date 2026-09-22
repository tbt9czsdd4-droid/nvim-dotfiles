require('nvim-treesitter').setup()

-- New windows start open; sessions can still restore their saved fold state.
vim.opt.foldlevel = 99

local function folds(buf)
    if not vim.treesitter.highlighter.active[buf] then return end
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        vim.wo[win].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.wo[win].foldmethod = 'expr'
    end
end

local group = vim.api.nvim_create_augroup('config-treesitter', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = function(event)
        if vim.bo[event.buf].buftype ~= '' or vim.bo[event.buf].filetype == 'bigfile' then return end
        -- Missing parsers leave ordinary syntax highlighting available.
        if pcall(vim.treesitter.start, event.buf) then folds(event.buf) end
    end,
})

vim.api.nvim_create_autocmd('BufWinEnter', {
    group = group,
    callback = function(event) folds(event.buf) end,
})

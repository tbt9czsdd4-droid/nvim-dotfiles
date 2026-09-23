require('nvim-treesitter').setup()

local group = vim.api.nvim_create_augroup('config-treesitter', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = function(event)
        if vim.bo[event.buf].buftype ~= '' or vim.bo[event.buf].filetype == 'bigfile' then return end
        -- Missing parsers leave ordinary syntax highlighting available.
        pcall(vim.treesitter.start, event.buf)
    end,
})

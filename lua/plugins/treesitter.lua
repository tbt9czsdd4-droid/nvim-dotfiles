local parsers = {
    'bash',
    'c',
    'cpp',
    'diff',
    'html',
    'json',
    'lua',
    'luadoc',
    'markdown',
    'markdown_inline',
    'python',
    'query',
    'rust',
    'toml',
    'vim',
    'vimdoc',
    'vhdl',
    'yaml',
}

local filetypes = {
    'c',
    'cpp',
    'html',
    'json',
    'lua',
    'markdown',
    'python',
    'rust',
    'sh',
    'toml',
    'vim',
    'vhdl',
    'yaml',
}

local max_treesitter_file_size = 5 * 1024 * 1024

local function is_large_file(buf)
    local path = vim.api.nvim_buf_get_name(buf)
    local ok, stat = pcall(vim.uv.fs_stat, path)

    return ok and stat ~= nil and stat.size > max_treesitter_file_size
end

local treesitter = require 'nvim-treesitter'
treesitter.setup()
treesitter.install(parsers)

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('kickstart-treesitter', { clear = true }),
    pattern = filetypes,
    callback = function(event)
        if is_large_file(event.buf) then
            vim.treesitter.stop(event.buf)
            vim.bo[event.buf].syntax = vim.bo[event.buf].filetype
            return
        end

        pcall(vim.treesitter.start, event.buf)
    end,
})

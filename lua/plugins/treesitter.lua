local treesitter = require 'nvim-treesitter'
treesitter.setup()

-- The parsers from the README's table, by row. A new machine installs them in
-- the background.
--stylua: ignore
local parsers = {
    'lua', 'luadoc', 'vim', 'vimdoc', 'query',
    'bash',
    'c', 'cpp',
    'python',
    'rust',
    'javascript', 'jsdoc', 'typescript', 'tsx', 'html', 'angular', 'css', 'scss',
    'json', 'yaml', 'toml', 'markdown', 'markdown_inline',
    'cmake', 'dockerfile',
    'latex', 'bibtex', 'typst', 'vhdl',
}

local function start(buffer)
    if vim.bo[buffer].buftype ~= '' or vim.bo[buffer].filetype == 'bigfile' then return end
    -- Missing parsers leave ordinary syntax highlighting available.
    pcall(vim.treesitter.start, buffer)
end

local group = vim.api.nvim_create_augroup('config-treesitter', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = function(event) start(event.buf) end,
})

-- Without these tools files keep Vim's syntax highlighting, instead of every
-- startup reporting an error for each parser.
local function can_build()
    for _, tool in ipairs { 'tree-sitter', 'cc', 'curl', 'tar' } do
        if vim.fn.executable(tool) == 0 then return false end
    end
    local version = vim.version.parse(vim.fn.system { 'tree-sitter', '--version' })
    return version ~= nil and vim.version.ge(version, { 0, 26, 1 })
end

vim.schedule(function()
    local installed = treesitter.get_installed()
    local missing = vim.tbl_filter(function(parser) return not vim.list_contains(installed, parser) end, parsers)
    if #missing == 0 or not can_build() then return end

    treesitter.install(missing, { summary = true }):await(vim.schedule_wrap(function()
        -- Files opened while installing get highlighting without reopening them.
        for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buffer) and not vim.treesitter.highlighter.active[buffer] then start(buffer) end
        end
    end))
end)

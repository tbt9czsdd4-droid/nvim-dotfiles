-- Locally the transparent colors/vim-modern.lua. Over SSH Vim's own default
-- scheme, with fixes where it breaks with these plugins.
vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('vim-scheme-fixes', { clear = true }),
    pattern = 'vim',
    callback = function()
        local set = vim.api.nvim_set_hl
        -- Neovim combines every tab bar segment with the reversed TabLineFill,
        -- and bufferline cannot derive colors from vim's empty Normal.
        set(0, 'TabLineFill', {})
        set(0, 'BufferLineBackground', { fg = 'Grey' })
        set(0, 'BufferLineBufferVisible', { fg = 'LightGrey' })
        for _, group in ipairs { 'BufferLineSeparator', 'BufferLineSeparatorVisible', 'BufferLineSeparatorSelected' } do
            set(0, group, { fg = 'Grey30' })
        end
        set(0, 'BufferLineIndicatorSelected', { fg = 'Yellow' })
        -- Floats (pickers, completion, popups) link to Pmenu, which is magenta.
        set(0, 'Pmenu', { bg = '#262626' })
        set(0, 'PmenuSel', { bg = '#4e4e4e', bold = true })
        set(0, 'PmenuSbar', { bg = '#3a3a3a' })
        -- A grey stripe and bold blue indent guides otherwise.
        set(0, 'SignColumn', { fg = 'Cyan' })
        set(0, 'SnacksIndent', { fg = 'Grey23' })
        -- Substitute links Search, so flash labels looked like their targets.
        set(0, 'FlashLabel', { fg = 'Black', bg = 'Magenta', bold = true })
    end,
})

vim.cmd.colorscheme(vim.g.is_ssh and 'vim' or 'vim-modern')

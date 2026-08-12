require('tokyonight').setup {
    style = 'night',
    transparent = true,
    terminal_colors = true,
    styles = {
        comments = { italic = false },
        keywords = { italic = false },
        sidebars = 'transparent',
        floats = 'transparent',
    },
    on_highlights = function(hl)
        local transparent = {
            'Normal',
            'NormalNC',
            'NormalFloat',
            'FloatBorder',
            'SignColumn',
            'FoldColumn',
            'EndOfBuffer',
            'MsgArea',
            'WinSeparator',
        }

        for _, group in ipairs(transparent) do
            hl[group] = vim.tbl_extend('force', hl[group] or {}, { bg = 'NONE' })
        end
    end,
}

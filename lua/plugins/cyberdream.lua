require('cyberdream').setup {
    variant = 'default',
    transparent = not vim.g.is_ssh,
    italic_keywords = false,
    terminal_colors = false,
    highlights = {
        CursorLineNr = { fg = '#ff9e64', bg = '#2a2e36', bold = true },
    },
}

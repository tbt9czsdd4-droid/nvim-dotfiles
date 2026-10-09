-- Neovim's default background and foreground; mini.hues adds plugin highlights.
local hues = require 'mini.hues'
hues.setup {
    background = '#14161b',
    foreground = '#e0e2ea',
    saturation = 'medium',
}
local palette = hues.get_palette()

-- Flash links matches and labels to Search and Substitute, which mini.hues
-- colors almost alike. Dark matches and bright labels keep jump targets apart.
vim.api.nvim_set_hl(0, 'FlashMatch', { fg = palette.fg, bg = palette.blue_bg })
vim.api.nvim_set_hl(0, 'FlashLabel', { fg = palette.bg_edge2, bg = palette.red, bold = true })

-- Locally the terminal shows through the editor, floats and the tab bar.
-- Over SSH the backgrounds stay, so bufferline can shade its tabs from them.
if not vim.g.is_ssh then
    local clear = {}
    for _, color in ipairs { palette.bg, palette.bg_edge } do
        clear[tonumber(color:sub(2), 16)] = true
    end
    for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
        if clear[hl.bg] then
            hl.bg = nil
            vim.api.nvim_set_hl(0, name, hl)
        end
    end
end

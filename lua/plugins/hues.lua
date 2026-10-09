-- Neovim's default background and foreground; mini.hues adds plugin highlights.
local background = '#14161b'
require('mini.hues').setup {
    background = background,
    foreground = '#e0e2ea',
    saturation = 'medium',
}

-- Locally the terminal shows through. Over SSH the background stays, so
-- bufferline can shade its tabs from it.
if not vim.g.is_ssh then
    local bg = tonumber(background:sub(2), 16)
    for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
        if hl.bg == bg then
            hl.bg = nil
            vim.api.nvim_set_hl(0, name, hl)
        end
    end
end

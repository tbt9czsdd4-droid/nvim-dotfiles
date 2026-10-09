-- Lualine's 'auto' theme loads this for `:colorscheme vim-modern`.
-- Colors come from the active highlight groups, so the palette lives in one place.
local function color(group, attr)
    local value = vim.api.nvim_get_hl(0, { name = group, link = false })[attr]
    return value and ('#%06x'):format(value) or 'NONE'
end

local fg, dim, panel = color('Normal', 'fg'), color('StatusLineNC', 'fg'), color('CursorLine', 'bg')

local function mode(group)
    return {
        a = { fg = '#121212', bg = color(group, 'fg'), gui = 'bold' },
        b = { fg = fg, bg = panel },
        c = { fg = fg, bg = 'NONE' },
    }
end

return {
    normal = mode 'Comment',
    insert = mode 'Type',
    visual = mode 'PreProc',
    replace = mode 'Error',
    command = mode 'Statement',
    terminal = mode 'Function',
    inactive = {
        a = { fg = dim, bg = 'NONE' },
        b = { fg = dim, bg = 'NONE' },
        c = { fg = dim, bg = 'NONE' },
    },
}

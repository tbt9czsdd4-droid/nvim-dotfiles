-- Vim's default colors on a transparent background. Everything comes from
-- Neovim's copy of Vim's scheme; changed below is only what breaks
-- transparency or the plugins in this config, plus calmer details: variables,
-- brackets and operators stay plain as in Vim's own syntax files, line numbers
-- are grey and the cursorline is dark.
vim.cmd.runtime 'colors/vim.lua'
vim.g.colors_name = 'vim-classic'

-- Force: links must replace the ones vim.lua and the plugins define.
local function hi(name, val)
    val.force = true
    vim.api.nvim_set_hl(0, name, val)
end

--stylua: ignore start
-- Vim leaves Normal empty; a foreground lets plugins derive their colors.
-- No backgrounds where the terminal should show through.
hi('Normal',       { fg = 'LightGrey' })
-- Floats (pickers, explorer, docs) link to Pmenu, which is magenta.
hi('NormalFloat',  { link = 'Normal' })
hi('FloatBorder',  { fg = 'Grey' })
hi('Pmenu',        { bg = 'Grey11' })
-- Vim's DarkGrey selection leaves light text unreadable; use its Visual grey.
hi('PmenuSel',     { bg = '#575757', bold = true })
hi('BlinkCmpMenuBorder', { fg = 'Grey', bg = 'Grey11' })
-- A grey stripe otherwise.
hi('SignColumn',   { fg = 'Cyan' })
hi('FoldColumn',   { fg = 'Cyan' })
-- Neovim combines every tab bar segment with the reversed TabLineFill.
hi('TabLineFill',  {})
-- NonText is pure blue, too dark for text that has to be read.
hi('LspInlayHint', { fg = 'Grey' })

-- Grey line numbers, a dark cursorline that the #575757 selection stands out
-- from, and dark grey filler characters and window separators.
hi('LineNr',       { fg = 'Grey' })
hi('CursorLine',   { bg = 'Grey15' })
hi('CursorColumn', { bg = 'Grey15' })
hi('NonText',      { fg = 'Grey30' })
hi('WinSeparator', { fg = 'Grey30' })

-- Neovim's vim scheme makes every treesitter variable cyan and every bracket orange.
hi('@variable',            {})
hi('@variable.member',     { link = '@variable' })
hi('@variable.parameter',  { link = '@variable' })
hi('@property',            { link = '@variable' })
hi('@module',              { link = '@variable' })
hi('@lsp.type.variable',   { link = '@variable' })
hi('@lsp.type.parameter',  { link = '@variable' })
hi('@lsp.type.property',   { link = '@variable' })
hi('@punctuation',         {})
hi('@punctuation.special', { link = 'Special' })
hi('@operator',            {})

hi('BufferLineBackground',        { fg = 'Grey' })
hi('BufferLineBufferVisible',     { fg = 'LightGrey' })
hi('BufferLineBufferSelected',    { fg = 'LightGrey', bold = true })
hi('BufferLineSeparator',         { fg = 'Grey30' })
hi('BufferLineSeparatorVisible',  { fg = 'Grey30' })
hi('BufferLineSeparatorSelected', { fg = 'Grey30' })
hi('BufferLineIndicatorSelected', { fg = 'Yellow' })

-- Picker paths and counts use NonText and Conceal (a grey block).
for _, name in ipairs { 'Dir', 'PathHidden', 'PathIgnored', 'Totals', 'Unselected', 'BufFlags', 'KeymapRhs', 'GitStatusUntracked', 'GitStatusIgnored', 'Dimmed' } do
    hi('SnacksPicker' .. name, { fg = 'Grey' })
end
hi('SnacksIndent',      { fg = 'Grey23' })
hi('SnacksIndentScope', { fg = 'Grey' })

-- Matches look like / search; labels must not, so they get their own color.
-- Flash and treesitter-context set their groups only once, so they are all
-- defined here to survive switching color schemes.
hi('FlashBackdrop',   { fg = 'Grey' })
hi('FlashMatch',      { link = 'Search' })
-- IncSearch (reverse) would turn grey over the backdrop; reverse Normal instead.
hi('FlashCurrent',    { fg = 'Black', bg = 'LightGrey' })
hi('FlashLabel',      { fg = 'Black', bg = 'Magenta', bold = true })
hi('FlashPrompt',     { link = 'MsgArea' })
hi('FlashPromptIcon', { link = 'Special' })
hi('FlashCursor',     { link = 'Cursor' })

hi('TreesitterContext',                 { bg = 'Grey11' })
hi('TreesitterContextLineNumber',       { fg = 'Grey', bg = 'Grey11' })
hi('TreesitterContextBottom',           { underline = true, sp = 'Grey' })
hi('TreesitterContextLineNumberBottom', { underline = true, sp = 'Grey' })
hi('TreesitterContextSeparator',        { link = 'FloatBorder' })
--stylua: ignore end

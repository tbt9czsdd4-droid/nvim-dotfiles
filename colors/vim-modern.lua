-- Vim's default colors, softened, on a transparent background.
-- Syntax keeps Vim's roles: yellow keywords, green types, cyan functions,
-- blue comments, salmon constants, magenta preprocessor, orange specials.
vim.cmd.highlight 'clear'
vim.g.colors_name = 'vim-modern'

local c = {
    fg = '#d4d4d4',
    dim = '#8a8a8a',
    dark = '#121212',
    grey1 = '#1c1c1c',
    grey2 = '#262626',
    grey3 = '#3a3a3a',
    grey4 = '#585858',
    yellow = '#e8d870',
    green = '#80d880',
    cyan = '#6fd6d6',
    blue = '#7d9af0',
    salmon = '#f0a0a0',
    magenta = '#e088e0',
    orange = '#f0a050',
    red = '#f06c6c',
}

-- Force: `hi clear` restores Neovim's default colors, which would block links.
local function hi(name, val)
    val.force = true
    vim.api.nvim_set_hl(0, name, val)
end

--stylua: ignore start
-- Editor. No backgrounds where the terminal should show through.
hi('Normal',       { fg = c.fg })
hi('NormalFloat',  { fg = c.fg })
hi('FloatBorder',  { fg = c.grey4 })
hi('FloatTitle',   { fg = c.magenta, bold = true })
hi('FloatFooter',  { fg = c.dim })
hi('Cursor',       { fg = c.dark, bg = c.fg })
hi('CursorLine',   { bg = c.grey2 })
hi('CursorColumn', { bg = c.grey2 })
hi('ColorColumn',  { bg = c.grey1 })
hi('LineNr',       { fg = c.grey4 })
hi('CursorLineNr', { fg = c.yellow, bold = true })
hi('SignColumn',   {})
hi('FoldColumn',   { fg = c.grey4 })
hi('Folded',       { fg = c.blue, bg = c.grey1 })
hi('NonText',      { fg = c.grey4 })
hi('Whitespace',   { fg = c.grey3 })
hi('SpecialKey',   { fg = c.grey4 })
hi('EndOfBuffer',  { fg = c.grey3 })
hi('Conceal',      { fg = c.dim })
hi('WinSeparator', { fg = c.grey3 })
hi('StatusLine',   { fg = c.fg })
hi('StatusLineNC', { fg = c.dim })
hi('TabLine',      { fg = c.dim })
hi('TabLineSel',   { fg = c.fg, bold = true })
hi('TabLineFill',  {})
hi('WinBar',       { fg = c.fg, bold = true })
hi('WinBarNC',     { fg = c.dim })
hi('Visual',       { bg = c.grey3 })
hi('VisualNOS',    { bg = c.grey3 })
hi('Search',       { fg = c.dark, bg = c.yellow })
hi('CurSearch',    { fg = c.dark, bg = c.orange })
hi('IncSearch',    { fg = c.dark, bg = c.orange })
hi('Substitute',   { fg = c.dark, bg = c.salmon })
hi('MatchParen',   { bg = '#1f5050', bold = true })
hi('Pmenu',        { fg = c.fg, bg = c.grey1 })
hi('PmenuSel',     { bg = c.grey3, bold = true })
hi('PmenuSbar',    { bg = c.grey2 })
hi('PmenuThumb',   { bg = c.grey4 })
hi('PmenuMatch',   { fg = c.orange, bold = true })
hi('PmenuMatchSel', { fg = c.orange, bg = c.grey3, bold = true })
hi('PmenuKind',    { fg = c.cyan })
hi('PmenuExtra',   { fg = c.dim })
hi('Directory',    { fg = c.cyan })
hi('Title',        { fg = c.magenta, bold = true })
hi('Question',     { fg = c.green, bold = true })
hi('MoreMsg',      { fg = c.green, bold = true })
hi('OkMsg',        { fg = c.green })
hi('ModeMsg',      { fg = c.fg, bold = true })
hi('WarningMsg',   { fg = c.orange })
hi('ErrorMsg',     { fg = c.red, bold = true })
hi('QuickFixLine', { bg = c.grey2, bold = true })
hi('SpellBad',     { sp = c.red, undercurl = true })
hi('SpellCap',     { sp = c.blue, undercurl = true })
hi('SpellLocal',   { sp = c.cyan, undercurl = true })
hi('SpellRare',    { sp = c.magenta, undercurl = true })
hi('DiffAdd',      { bg = '#1f3a24' })
hi('DiffChange',   { bg = '#1e2a40' })
hi('DiffDelete',   { fg = c.red, bg = '#3f1f22' })
hi('DiffText',     { bg = '#2f4a78' })
hi('Added',        { fg = c.green })
hi('Changed',      { fg = c.blue })
hi('Removed',      { fg = c.red })

-- Syntax, following Vim's own links.
hi('Comment',      { fg = c.blue })
hi('Constant',     { fg = c.salmon })
hi('String',       { link = 'Constant' })
hi('Character',    { link = 'Constant' })
hi('Number',       { link = 'Constant' })
hi('Boolean',      { link = 'Constant' })
hi('Float',        { link = 'Constant' })
hi('Identifier',   { fg = c.cyan })
hi('Function',     { link = 'Identifier' })
hi('Statement',    { fg = c.yellow, bold = true })
hi('Conditional',  { link = 'Statement' })
hi('Repeat',       { link = 'Statement' })
hi('Label',        { link = 'Statement' })
hi('Keyword',      { link = 'Statement' })
hi('Exception',    { link = 'Statement' })
hi('Operator',     { fg = c.yellow })
hi('PreProc',      { fg = c.magenta })
hi('Include',      { link = 'PreProc' })
hi('Define',       { link = 'PreProc' })
hi('Macro',        { link = 'PreProc' })
hi('PreCondit',    { link = 'PreProc' })
hi('Type',         { fg = c.green, bold = true })
hi('StorageClass', { link = 'Type' })
hi('Structure',    { link = 'Type' })
hi('Typedef',      { link = 'Type' })
hi('Special',      { fg = c.orange })
hi('SpecialChar',  { link = 'Special' })
hi('Tag',          { link = 'Special' })
hi('SpecialComment', { link = 'Special' })
hi('Debug',        { link = 'Special' })
hi('Delimiter',    { fg = c.dim })
hi('Underlined',   { fg = c.blue, underline = true })
hi('Ignore',       { fg = c.grey3 })
hi('Error',        { fg = c.red, bold = true })
hi('Todo',         { fg = c.dark, bg = c.yellow, bold = true })

-- Treesitter: variables stay plain instead of Vim's cyan.
hi('@variable',           { fg = c.fg })
hi('@variable.member',    { link = '@variable' })
hi('@variable.parameter', { link = '@variable' })
hi('@property',           { link = '@variable' })
hi('@module',             { link = '@variable' })
hi('@constant.builtin',   { link = 'Special' })
hi('@function.builtin',   { link = 'Special' })
hi('@constructor',        { link = 'Special' })
hi('@markup.heading',     { link = 'Title' })
hi('@markup.link.url',    { link = 'Underlined' })
hi('@markup.raw',         { link = 'Comment' })

-- Diagnostics and LSP.
hi('DiagnosticError',            { fg = c.red })
hi('DiagnosticWarn',             { fg = c.orange })
hi('DiagnosticInfo',             { fg = c.blue })
hi('DiagnosticHint',             { fg = c.dim })
hi('DiagnosticOk',               { fg = c.green })
hi('DiagnosticUnderlineError',   { sp = c.red, undercurl = true })
hi('DiagnosticUnderlineWarn',    { sp = c.orange, undercurl = true })
hi('DiagnosticUnderlineInfo',    { sp = c.blue, undercurl = true })
hi('DiagnosticUnderlineHint',    { sp = c.dim, undercurl = true })
hi('DiagnosticUnderlineOk',      { sp = c.green, undercurl = true })
hi('DiagnosticDeprecated',       { sp = c.red, strikethrough = true })
hi('DiagnosticUnnecessary',      { fg = c.grey4 })
hi('LspReferenceText',           { bg = c.grey2 })
hi('LspReferenceRead',           { bg = c.grey2 })
hi('LspReferenceWrite',          { bg = c.grey2, bold = true })
hi('LspInlayHint',               { fg = c.grey4 })
hi('LspCodeLens',                { fg = c.grey4 })
hi('LspSignatureActiveParameter', { fg = c.yellow, bold = true })

-- Plugins, where linking to the groups above is not enough.
hi('BufferLineBackground',        { fg = c.dim })
hi('BufferLineBufferVisible',     { fg = c.fg })
hi('BufferLineBufferSelected',    { fg = c.fg, bold = true })
hi('BufferLineSeparator',         { fg = c.grey3 })
hi('BufferLineSeparatorVisible',  { fg = c.grey3 })
hi('BufferLineSeparatorSelected', { fg = c.grey3 })
hi('BufferLineIndicatorSelected', { fg = c.yellow })
hi('FlashMatch',    { fg = c.fg, bg = '#1e2a40' })
hi('FlashLabel',    { fg = c.dark, bg = c.magenta, bold = true })
hi('FlashCurrent',  { fg = c.dark, bg = c.orange })
hi('FlashBackdrop', { fg = c.grey4 })
hi('SnacksIndent',      { fg = '#303030' })
hi('SnacksIndentScope', { fg = c.grey4 })
--stylua: ignore end

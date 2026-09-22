local function diff_source()
    local summary = vim.b.minidiff_summary
    if not summary or not summary.add then return end

    return {
        added = summary.add,
        modified = summary.change,
        removed = summary.delete,
    }
end

local function workspace_name()
    local owner = require('config.sessions').owner()
    return owner and vim.fs.basename(owner) or 'Standalone'
end

require('lualine').setup {
    options = {
        theme = 'auto',
        globalstatus = true,
        component_separators = { left = '│', right = '│' },
        section_separators = { left = '', right = '' },
    },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', { 'diff', source = diff_source }, 'diagnostics' },
        lualine_c = {
            workspace_name,
            {
                'filename',
                path = 1,
            },
        },
        lualine_x = {
            { 'encoding', cond = function() return (vim.bo.fileencoding ~= '' and vim.bo.fileencoding or vim.o.encoding) ~= 'utf-8' end },
            { 'fileformat', cond = function() return vim.bo.fileformat ~= 'unix' end },
            'filetype',
        },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
    },
}

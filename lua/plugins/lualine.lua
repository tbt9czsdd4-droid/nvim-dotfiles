local function diff_source()
    local summary = vim.b.minidiff_summary
    if not summary or not summary.add then return end

    return {
        added = summary.add,
        modified = summary.change,
        removed = summary.delete,
    }
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
            {
                'filename',
                path = 1,
            },
        },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
    },
}

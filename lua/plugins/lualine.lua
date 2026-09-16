local function diff_source()
    local summary = vim.b.minidiff_summary
    if not summary or not summary.add then return end

    return {
        added = summary.add,
        modified = summary.change,
        removed = summary.delete,
    }
end

local baseline = {
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

local presets = {
    { name = 'auto', label = 'Original Cyberdream — current layout' },
    {
        name = 'nord-minimal',
        label = 'Nord — flat and compact',
        theme = 'nord',
        component_separators = { left = '', right = '' },
        sections = {
            lualine_b = { 'branch' },
            lualine_x = { 'diagnostics', 'filetype' },
            lualine_y = {},
        },
    },
    {
        name = 'dracula-rounded',
        label = 'Dracula — rounded sections',
        theme = 'dracula',
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        sections = {
            lualine_x = { 'filetype' },
        },
    },
    {
        name = 'gruvbox-powerline',
        label = 'Gruvbox Dark — classic arrows, full details',
        theme = 'gruvbox_dark',
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
    },
    {
        name = 'palenight-slanted',
        label = 'Palenight — slanted sections, filename first',
        theme = 'palenight',
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        sections = {
            lualine_b = { { 'filename', path = 1 } },
            lualine_c = { 'branch', { 'diff', source = diff_source }, 'diagnostics' },
            lualine_x = { 'filetype' },
        },
    },
    {
        name = 'iceberg-quiet',
        label = 'Iceberg Dark — muted, thin dividers',
        theme = 'iceberg_dark',
        sections = {
            lualine_b = { 'branch', { 'diff', source = diff_source } },
            lualine_x = { 'diagnostics' },
            lualine_y = {},
        },
    },
}

local lualine = require 'lualine'
local current = 'auto'

local function apply_preset(name)
    for _, preset in ipairs(presets) do
        if preset.name == name then
            local config = vim.deepcopy(baseline)
            config.options.theme = preset.theme or 'auto'
            for _, option in ipairs { 'component_separators', 'section_separators' } do
                if preset[option] then config.options[option] = vim.deepcopy(preset[option]) end
            end
            -- Replace whole component lists, including empty sections, on each switch.
            for section, components in pairs(preset.sections or {}) do
                config.sections[section] = vim.deepcopy(components)
            end
            lualine.setup(config)
            current = name
            return
        end
    end
    vim.notify('Unknown lualine preset: ' .. name .. '. Use :LualinePreview to choose one.', vim.log.levels.WARN)
end

-- Previews are session-only; startup always restores the original configuration.
apply_preset 'auto'

vim.api.nvim_create_user_command('LualinePreview', function(opts)
    if opts.args ~= '' then
        apply_preset(opts.args)
        return
    end
    vim.ui.select(presets, {
        prompt = 'Lualine preview (restart restores auto)',
        format_item = function(preset)
            local marker = preset.name == current and ' [active]' or ''
            return preset.name .. ' — ' .. preset.label .. marker
        end,
    }, function(preset)
        if preset then apply_preset(preset.name) end
    end)
end, {
    desc = 'Preview lualine styles for this session',
    nargs = '?',
    complete = function(prefix)
        local names = {}
        for _, preset in ipairs(presets) do
            if vim.startswith(preset.name, prefix) then names[#names + 1] = preset.name end
        end
        return names
    end,
})

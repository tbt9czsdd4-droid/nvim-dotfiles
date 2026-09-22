require('grug-far').setup {
    keymaps = {
        replace = { n = '<leader>r' },
    },
    enabledEngines = { 'ripgrep' },
    engines = {
        ripgrep = { extraArgs = '--hidden --glob=!.git' },
    },
    hooks = {
        -- Replacement operates on disk: don't overwrite a file being edited.
        on_before_edit_file = function(finish, file)
            if not file.isBufferRange then
                local path = vim.uv.fs_realpath(file.path) or vim.fn.fnamemodify(file.path, ':p')
                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.bo[buf].modified then
                        local name = vim.api.nvim_buf_get_name(buf)
                        if (vim.uv.fs_realpath(name) or name) == path then
                            finish('error', 'Save or discard unsaved changes before replacing: ' .. file.path)
                            return
                        end
                    end
                end
            end
            finish 'success'
        end,
    },
}

vim.keymap.set({ 'n', 'x' }, '<leader>sr', function()
    local root = require('config.project').root()
    require('grug-far').open {
        windowCreationCommand = vim.o.columns >= 120 and 'botright vsplit' or 'botright split',
        -- Grug-far's Paths input separates spaces with backslashes, not quotes.
        prefills = { paths = root:gsub(' ', '\\ ') },
        visualSelectionUsage = 'prefill-search',
    }
end, { desc = 'Search and replace (workspace)' })

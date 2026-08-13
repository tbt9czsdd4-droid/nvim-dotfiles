vim.loader.enable()

-- Must be defined before plugins are loaded.
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'
vim.g.have_nerd_font = true

vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function()
        if vim.fn.argc() ~= 1 then return end

        local arg = vim.fn.argv(0)
        local path = vim.fn.fnamemodify(arg, ':p')

        if vim.fn.isdirectory(path) == 1 then
            vim.api.nvim_set_current_dir(path)

            -- Let directory/explorer startup handling finish first, then remove
            -- the directory argument so it is not written into project sessions.
            vim.schedule(function()
                vim.cmd 'silent! %argdelete'

                local persistence = require 'persistence'
                local session = persistence.current()
                local fallback = persistence.current { branch = false }

                if vim.fn.filereadable(session) == 1 or vim.fn.filereadable(fallback) == 1 then
                    for _, picker in ipairs(Snacks.picker.get { source = 'explorer' }) do
                        picker:close()
                    end

                    persistence.load()
                end
            end)
        end
    end,
})

-- experimental
vim.o.cmdheight = 0
require('vim._core.ui2').enable {}

require 'config.options'
require 'config.keymaps'
require 'config.autocmds'
require 'config.pack'
require 'plugins'

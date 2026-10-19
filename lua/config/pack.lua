vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(event)
        local data = event.data
        if data.spec.name ~= 'nvim-treesitter' then return end
        if data.kind ~= 'update' then return end

        if not data.active then vim.cmd.packadd 'nvim-treesitter' end
        require('nvim-treesitter').update(nil, { summary = true })
    end,
    desc = 'Update Treesitter parsers after package changes',
})

vim.pack.add {
    { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range '1.*' },
    { src = 'https://github.com/akinsho/bufferline.nvim' },
    { src = 'https://github.com/stevearc/conform.nvim' },
    { src = 'https://github.com/scottmckendry/cyberdream.nvim' },
    { src = 'https://github.com/folke/flash.nvim' },
    { src = 'https://github.com/rafamadriz/friendly-snippets' },
    { src = 'https://github.com/nvim-lualine/lualine.nvim' },
    { src = 'https://github.com/mason-org/mason.nvim' },
    { src = 'https://github.com/nvim-mini/mini.nvim' },
    { src = 'https://github.com/neovim/nvim-lspconfig' },
    { src = 'https://github.com/abecodes/tabout.nvim' },
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter-context' },
    { src = 'https://github.com/folke/snacks.nvim' },
    { src = 'https://github.com/MagicDuck/grug-far.nvim' },
}

-- Update plugins on one machine and commit the lockfile. Elsewhere, pull and
-- run this: plugins move to the locked revisions, and those the config no
-- longer adds are removed.
vim.api.nvim_create_user_command('LockfileSync', function()
    local stale = vim.iter(vim.pack.get(nil, { info = false }))
        :filter(function(plugin) return not plugin.active end)
        :map(function(plugin) return plugin.spec.name end)
        :totable()
    if #stale > 0 then vim.pack.del(stale) end
    vim.pack.update(nil, { target = 'lockfile' })
end, { desc = 'Match installed plugins to the lockfile' })

vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(event)
        local data = event.data
        if data.spec.name ~= 'nvim-treesitter' then return end
        if data.kind ~= 'install' and data.kind ~= 'update' then return end

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
    { src = 'https://github.com/mason-org/mason-lspconfig.nvim' },
    { src = 'https://github.com/jay-babu/mason-nvim-dap.nvim' },
    { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' },
    { src = 'https://github.com/mason-org/mason.nvim' },
    { src = 'https://github.com/nvim-mini/mini.nvim' },
    { src = 'https://github.com/nvim-mini/mini.starter' },
    { src = 'https://github.com/mfussenegger/nvim-dap' },
    { src = 'https://github.com/rcarriga/nvim-dap-ui' },
    { src = 'https://github.com/theHamsta/nvim-dap-virtual-text' },
    { src = 'https://github.com/neovim/nvim-lspconfig' },
    { src = 'https://github.com/nvim-neotest/nvim-nio' },
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
    { src = 'https://github.com/folke/persistence.nvim' },
    { src = 'https://github.com/folke/snacks.nvim' },
    { src = 'https://github.com/folke/tokyonight.nvim' },
    { src = 'https://github.com/folke/which-key.nvim' },
    { src = 'https://github.com/gbprod/yanky.nvim' },
}

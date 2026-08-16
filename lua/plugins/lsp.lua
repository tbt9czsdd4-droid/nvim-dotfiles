local servers = {
    'bashls',
    'clangd',
    'lua_ls',
    'markdown_oxide',
    'pyright',
    'rust_analyzer',
}

local capabilities = require('blink.cmp').get_lsp_capabilities()
local pick = require 'mini.pick'
local pickers = require('mini.extra').pickers

local function pick_lsp_locations(scope)
    local on_list = function(data)
        for _, item in ipairs(data.items) do
            item.path = item.filename or vim.api.nvim_buf_get_name(item.bufnr or 0)
            item.text = string.format('%s:%d:%d %s', vim.fn.fnamemodify(item.path, ':.'), item.lnum or 1, item.col or 1, item.text or '')
        end

        if #data.items == 1 then return pick.default_choose(data.items[1]) end

        pick.start {
            source = {
                items = data.items,
                name = data.title or ('LSP (' .. scope .. ')'),
            },
        }
    end

    if scope == 'references' then
        vim.lsp.buf.references(nil, { on_list = on_list })
    else
        vim.lsp.buf[scope] { on_list = on_list }
    end
end

vim.lsp.config('*', {
    capabilities = capabilities,
})

vim.lsp.config('markdown_oxide', {
    on_init = function(client)
        local operations = vim.tbl_get(client.server_capabilities, 'workspace', 'fileOperations')

        for _, capability in pairs(operations or {}) do
            for _, filter in ipairs(capability.filters or {}) do
                if filter.scheme == vim.NIL then filter.scheme = nil end
            end
        end
    end,
})

vim.lsp.config('clangd', {
    cmd = {
        'clangd',
        '--background-index',
        '--clang-tidy',
        '--completion-style=detailed',
    },
})

vim.lsp.config('lua_ls', {
    settings = {
        Lua = {
            completion = {
                callSnippet = 'Replace',
            },
            diagnostics = {
                globals = { 'vim', 'Snacks', 'MiniIcons' },
            },
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME,
                },
            },
        },
    },
})

vim.lsp.config('rust_analyzer', {
    settings = {
        ['rust-analyzer'] = {
            cargo = {
                allFeatures = true,
            },
            check = {
                command = 'clippy',
            },
        },
    },
})

vim.diagnostic.config {
    severity_sort = true,
    float = {
        border = 'rounded',
        source = 'if_many',
    },
    signs = true,
    underline = true,
    virtual_text = {
        source = 'if_many',
        spacing = 2,
        prefix = '●',
    },
}

local group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true })
vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(event)
        local function map(keys, func, desc, mode)
            vim.keymap.set(mode or 'n', keys, func, {
                buffer = event.buf,
                desc = 'LSP: ' .. desc,
            })
        end

        map('gd', function() pick_lsp_locations 'definition' end, 'Goto definition')
        map('gr', function() pick_lsp_locations 'references' end, 'References')
        map('gI', function() pick_lsp_locations 'implementation' end, 'Goto implementation')
        map('gy', function() pick_lsp_locations 'type_definition' end, 'Goto type definition')
        map('gD', vim.lsp.buf.declaration, 'Goto declaration')
        map('K', vim.lsp.buf.hover, 'Hover documentation')
        map('<leader>ca', vim.lsp.buf.code_action, 'Code action', { 'n', 'x' })
        map('<leader>cr', vim.lsp.buf.rename, 'Rename')
        map('<leader>ss', function() pickers.lsp { scope = 'document_symbol' } end, 'Document symbols')
        map('<leader>sS', function() pickers.lsp { scope = 'workspace_symbol_live' } end, 'Workspace symbols')

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>uh', function()
                local enabled = vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }
                vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
            end, 'Toggle inlay hints')
        end
    end,
})

require('mason-lspconfig').setup {
    ensure_installed = servers,
    automatic_enable = true,
}

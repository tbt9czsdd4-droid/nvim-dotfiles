-- Supported servers and their executables. A server is enabled once its
-- executable is on PATH; Mason's bin directory comes first.
local servers = {
    angularls = 'ngserver',
    bashls = 'bash-language-server',
    clangd = 'clangd',
    docker_compose_language_service = 'docker-compose-langserver',
    dockerls = 'docker-langserver',
    jsonls = 'vscode-json-language-server',
    lua_ls = 'lua-language-server',
    markdown_oxide = 'markdown-oxide',
    neocmake = 'neocmakelsp',
    pyright = 'pyright-langserver',
    ruff = 'ruff',
    rust_analyzer = 'rust-analyzer',
    taplo = 'taplo',
    texlab = 'texlab',
    tinymist = 'tinymist',
    vtsls = 'vtsls',
    yamlls = 'yaml-language-server',
}

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
            check = {
                command = 'clippy',
            },
        },
    },
})

vim.diagnostic.config {
    severity_sort = true,
    float = {
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

        map('gd', function() Snacks.picker.lsp_definitions() end, 'Goto definition')
        map('grr', function() Snacks.picker.lsp_references() end, 'References')
        map('gI', function() Snacks.picker.lsp_implementations() end, 'Goto implementation')
        map('gy', function() Snacks.picker.lsp_type_definitions() end, 'Goto type definition')
        map('gD', vim.lsp.buf.declaration, 'Goto declaration')
        map('<leader>ca', vim.lsp.buf.code_action, 'Code action', { 'n', 'x' })
        map('<leader>cr', vim.lsp.buf.rename, 'Rename')
        map('<leader>ss', function() Snacks.picker.lsp_symbols() end, 'Document symbols')
        map('<leader>sS', function() Snacks.picker.lsp_workspace_symbols() end, 'Workspace symbols')

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>uh', function()
                local enabled = vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }
                vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
            end, 'Toggle inlay hints')
        end
    end,
})

local function enable_available()
    for server, executable in pairs(servers) do
        if not vim.lsp.is_enabled(server) and vim.fn.executable(executable) == 1 then vim.lsp.enable(server) end
    end
end

enable_available()
-- Servers installed with :MasonInstall start without a restart.
require('mason-registry'):on('package:install:success', vim.schedule_wrap(enable_available))

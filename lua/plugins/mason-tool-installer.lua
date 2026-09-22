require('mason-tool-installer').setup {
    ensure_installed = {
        'clang-format',
        'ruff',
        'shfmt',
        'stylua',
        'prettier',
    },
    run_on_start = false,
}

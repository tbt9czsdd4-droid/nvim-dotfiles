require('mason-tool-installer').setup {
  ensure_installed = {
    'clang-format',
    'ruff',
    'shfmt',
    'stylua',
  },
  run_on_start = true,
  start_delay = 1000,
  debounce_hours = 24,
}

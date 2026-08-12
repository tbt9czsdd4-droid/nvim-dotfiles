require('blink.cmp').setup {
  keymap = {
    preset = 'enter',
  },
  appearance = {
    nerd_font_variant = 'mono',
  },
  completion = {
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 250,
    },
    ghost_text = {
      enabled = false,
    },
  },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },
  signature = {
    enabled = true,
  },
  fuzzy = {
    implementation = 'prefer_rust_with_warning',
  },
}

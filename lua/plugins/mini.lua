local icons = require 'mini.icons'
icons.setup {
  style = vim.g.have_nerd_font and 'glyph' or 'ascii',
}
icons.mock_nvim_web_devicons()

require('mini.pairs').setup {
  modes = {
    insert = true,
    command = true,
    terminal = false,
  },
}

require('mini.files').setup {
  options = {
    -- Keep Snacks as the explorer used for `nvim <directory>`.
    use_as_default_explorer = false,
  },
  windows = {
    preview = true,
    width_focus = 30,
    width_nofocus = 15,
    width_preview = 50,
  },
}

vim.keymap.set('n', '<leader>e', function()
  local path = vim.api.nvim_buf_get_name(0)
  local MiniFiles = require 'mini.files'

  if path == '' then path = vim.uv.cwd() end
  MiniFiles.open(path, false)
end, { desc = 'Open mini.files' })

require('mini.move').setup {
  mappings = {
    left = '<M-h>',
    right = '<M-l>',
    down = '<M-j>',
    up = '<M-k>',
    line_left = '<M-h>',
    line_right = '<M-l>',
    line_down = '<M-j>',
    line_up = '<M-k>',
  },
}

local animate = require 'mini.animate'
animate.setup {
  cursor = {
    enable = true,
    timing = animate.gen_timing.linear { duration = 100, unit = 'total' },
  },
  scroll = {
    enable = true,
    timing = animate.gen_timing.linear { duration = 100, unit = 'total' },
  },
  -- Keep this disabled. It previously triggered the WezTerm resize/statusline bug.
  resize = {
    enable = false,
  },
  open = {
    enable = true,
    timing = animate.gen_timing.linear { duration = 100, unit = 'total' },
  },
  close = {
    enable = true,
    timing = animate.gen_timing.linear { duration = 100, unit = 'total' },
  },
}

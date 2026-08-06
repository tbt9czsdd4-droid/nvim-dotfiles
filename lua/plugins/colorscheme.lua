return {
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    opts = {
      style = 'night',
      transparent = true,
      terminal_colors = true,
      styles = {
        comments = { italic = false },
        keywords = { italic = false },
        sidebars = 'transparent',
        floats = 'transparent',
      },
      on_highlights = function(hl)
        local transparent = {
          'Normal',
          'NormalNC',
          'NormalFloat',
          'FloatBorder',
          'SignColumn',
          'FoldColumn',
          'EndOfBuffer',
          'MsgArea',
          'WinSeparator',
        }

        for _, group in ipairs(transparent) do
          hl[group] = vim.tbl_extend('force', hl[group] or {}, { bg = 'NONE' })
        end
      end,
    },
    config = function(_, opts)
      require('tokyonight').setup(opts)
      -- vim.cmd.colorscheme 'tokyonight-night'
    end,
  },
  {
    'scottmckendry/cyberdream.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('cyberdream').setup {
        variant = 'default',
        transparent = true,
        italic_keywords = false,
        terminal_colors = false,
        -- saturation = 0.97,
      }
      vim.cmd.colorscheme 'cyberdream'
    end,
  },
}

return {
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',

    dependencies = {
      'nvim-mini/mini.nvim',
    },

    keys = {
      {
        '<S-h>',
        '<cmd>BufferLineCyclePrev<cr>',
        desc = 'Previous buffer',
      },
      {
        '<S-l>',
        '<cmd>BufferLineCycleNext<cr>',
        desc = 'Next buffer',
      },
      {
        '[b',
        '<cmd>BufferLineCyclePrev<cr>',
        desc = 'Previous buffer',
      },
      {
        ']b',
        '<cmd>BufferLineCycleNext<cr>',
        desc = 'Next buffer',
      },
      {
        '[B',
        '<cmd>BufferLineMovePrev<cr>',
        desc = 'Move buffer left',
      },
      {
        ']B',
        '<cmd>BufferLineMoveNext<cr>',
        desc = 'Move buffer right',
      },
      {
        '<leader>bp',
        '<cmd>BufferLineTogglePin<cr>',
        desc = 'Toggle buffer pin',
      },
      {
        '<leader>bP',
        '<cmd>BufferLineGroupClose ungrouped<cr>',
        desc = 'Delete non-pinned buffers',
      },
      {
        '<leader>br',
        '<cmd>BufferLineCloseRight<cr>',
        desc = 'Delete buffers to the right',
      },
      {
        '<leader>bl',
        '<cmd>BufferLineCloseLeft<cr>',
        desc = 'Delete buffers to the left',
      },
      {
        '<leader>bj',
        '<cmd>BufferLinePick<cr>',
        desc = 'Pick buffer',
      },
    },

    opts = {
      options = {
        mode = 'buffers',

        close_command = function(buffer_number) Snacks.bufdelete(buffer_number) end,

        right_mouse_command = function(buffer_number) Snacks.bufdelete(buffer_number) end,

        diagnostics = 'nvim_lsp',

        diagnostics_indicator = function(_, _, diagnostics)
          local result = ''

          if diagnostics.error then result = result .. '  ' .. diagnostics.error end

          if diagnostics.warning then result = result .. '  ' .. diagnostics.warning end

          return result
        end,

        always_show_bufferline = false,
        show_buffer_icons = true,
        show_buffer_close_icons = false,
        show_close_icon = false,
        separator_style = 'thin',

        offsets = {
          {
            filetype = 'snacks_layout_box',
          },
        },
      },
    },
  },
  -- {
  --   'rachartier/tiny-cmdline.nvim',
  --   init = function() vim.o.cmdheight = 0 end,
  -- },
  {
    'nvim-mini/mini.nvim',
    version = false,
    config = function()
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
    end,
  },

  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = {
      'nvim-mini/mini.nvim',
    },
    opts = {
      options = {
        theme = 'auto',
        globalstatus = true,
        component_separators = { left = '│', right = '│' },
        section_separators = { left = '', right = '' },
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = {
          {
            'filename',
            path = 1,
          },
        },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
    },
  },

  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    dependencies = {
      'nvim-mini/mini.nvim',
    },
    opts = {
      preset = 'helix',
      delay = 300,
      spec = {
        {
          mode = { 'n', 'x' },
          { '<leader>b', group = 'buffer' },
          { '<leader>c', group = 'code' },
          { '<leader>d', group = 'debug' },
          { '<leader>f', group = 'file/find' },
          { '<leader>q', group = 'quit/session' },
          { '<leader>s', group = 'search' },
          { '<leader>u', group = 'ui/toggles' },
          { '<leader>x', group = 'diagnostics/quickfix' },
          { '[', group = 'previous' },
          { ']', group = 'next' },
          { 'g', group = 'goto' },
          { 'z', group = 'fold' },
        },
      },
    },
    keys = {
      {
        '<leader>?',
        function() require('which-key').show { global = false } end,
        desc = 'Buffer-local keymaps',
      },
    },
  },
}

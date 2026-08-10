local root_markers = {
  '.git',
  'Cargo.toml',
  'pyproject.toml',
  'CMakeLists.txt',
  'Makefile',
  'package.json',
}

local function project_root()
  local name = vim.api.nvim_buf_get_name(0)
  local start = name ~= '' and vim.fs.dirname(name) or vim.uv.cwd()
  return vim.fs.root(start, root_markers) or vim.uv.cwd()
end

return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      explorer = {
        enabled = true,
        replace_netrw = true,
      },
      picker = {
        enabled = true,
        ources = {
          projects = {
            confirm = function(picker, item)
              -- Save the project we are leaving.
              require('persistence').save()

              -- Change project and restore its saved session.
              Snacks.picker.actions.load_session(picker, item)
            end,
          },
        },
      },
      indent = {
        enabled = true,
        char = '│',
      },
      scope = {
        enabled = true,
        char = '|',
        underline = false,
      },
      terminal = {
        win = {
          position = 'bottom',
          border = 'top',
          height = 0.3,
        },
      },
    },
    keys = {
      {
        '<leader>ft',
        function()
          Snacks.terminal.toggle(nil, {
            cwd = project_root(),
          })
        end,
        desc = 'Terminal (project root)',
      },
      {
        '<leader>fT',
        function()
          Snacks.terminal.toggle(nil, {
            cwd = vim.uv.cwd(),
          })
        end,
        desc = 'Terminal (cwd)',
      },
      {
        '<leader><space>',
        function() Snacks.picker.files { cwd = project_root() } end,
        desc = 'Find files (project)',
      },
      {
        '<leader>/',
        function() Snacks.picker.grep { cwd = project_root() } end,
        desc = 'Grep project',
      },
      {
        '<leader>,',
        function() Snacks.picker.buffers() end,
        desc = 'Buffers',
      },
      {
        '<leader>:',
        function() Snacks.picker.command_history() end,
        desc = 'Command history',
      },
      {
        '<leader>E',
        function() Snacks.explorer { cwd = project_root() } end,
        desc = 'Explorer (project)',
      },
      {
        '<leader>o',
        function() Snacks.picker.treesitter() end,
        desc = 'Code outline',
      },
      {
        '<leader>ff',
        function() Snacks.picker.files { cwd = project_root() } end,
        desc = 'Find files (project)',
      },
      {
        '<leader>fF',
        function() Snacks.picker.files() end,
        desc = 'Find files (cwd)',
      },
      {
        '<leader>fg',
        function() Snacks.picker.git_files() end,
        desc = 'Find Git files',
      },
      {
        '<leader>fr',
        function() Snacks.picker.recent { filter = { cwd = true } } end,
        desc = 'Recent files (cwd)',
      },
      {
        '<leader>fR',
        function() Snacks.picker.recent() end,
        desc = 'Recent files',
      },
      {
        '<leader>fp',
        function() Snacks.picker.projects() end,
        desc = 'Projects',
      },
      {
        '<leader>fc',
        function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end,
        desc = 'Find config file',
      },
      {
        '<leader>sb',
        function() Snacks.picker.lines() end,
        desc = 'Buffer lines',
      },
      {
        '<leader>sB',
        function() Snacks.picker.grep_buffers() end,
        desc = 'Grep open buffers',
      },
      {
        '<leader>sg',
        function() Snacks.picker.grep { cwd = project_root() } end,
        desc = 'Grep project',
      },
      {
        '<leader>sG',
        function() Snacks.picker.grep() end,
        desc = 'Grep cwd',
      },
      {
        '<leader>sw',
        function() Snacks.picker.grep_word { cwd = project_root() } end,
        mode = { 'n', 'x' },
        desc = 'Search word/selection',
      },
      {
        '<leader>s"',
        function() Snacks.picker.registers() end,
        desc = 'Registers',
      },
      {
        '<leader>sa',
        function() Snacks.picker.autocmds() end,
        desc = 'Autocommands',
      },
      {
        '<leader>sc',
        function() Snacks.picker.command_history() end,
        desc = 'Command history',
      },
      {
        '<leader>sC',
        function() Snacks.picker.commands() end,
        desc = 'Commands',
      },
      {
        '<leader>sd',
        function() Snacks.picker.diagnostics() end,
        desc = 'Diagnostics',
      },
      {
        '<leader>sD',
        function() Snacks.picker.diagnostics_buffer() end,
        desc = 'Buffer diagnostics',
      },
      {
        '<leader>sh',
        function() Snacks.picker.help() end,
        desc = 'Help pages',
      },
      {
        '<leader>sk',
        function() Snacks.picker.keymaps() end,
        desc = 'Keymaps',
      },
      {
        '<leader>sm',
        function() Snacks.picker.marks() end,
        desc = 'Marks',
      },
      {
        '<leader>su',
        function() Snacks.picker.undo() end,
        desc = 'Undo history',
      },
    },
  },
}

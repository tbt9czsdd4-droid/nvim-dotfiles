vim.loader.enable()

-- Must be defined before plugins are loaded.
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'
vim.g.have_nerd_font = true

-- experimental
vim.o.cmdheight = 0
require('vim._core.ui2').enable {}

require 'config.options'
require 'config.keymaps'
require 'config.autocmds'
require 'config.pack'
require 'plugins'

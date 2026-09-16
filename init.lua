vim.loader.enable()

-- Must be defined before plugins are loaded.
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'
vim.g.have_nerd_font = true

-- Experimental UI is optional across Neovim versions.
local ui_ok, ui2 = pcall(require, 'vim._core.ui2')
if ui_ok then
    ui_ok = pcall(ui2.enable, {})
    if not ui_ok then pcall(ui2.enable, { enable = false }) end
end
vim.o.cmdheight = ui_ok and 0 or 1

require 'config.options'
require 'config.keymaps'
require 'config.autocmds'
require 'config.pack'
require 'plugins'

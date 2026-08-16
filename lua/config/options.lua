local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = 'a'
opt.showmode = false
opt.breakindent = true
opt.undofile = true

opt.ignorecase = true
opt.smartcase = true

opt.signcolumn = 'yes'
opt.updatetime = 250
opt.timeoutlen = 300

opt.splitright = true
opt.splitbelow = true

opt.showmode = false
opt.cmdheight = 0
opt.breakindent = true

opt.list = true
opt.listchars = {
    tab = '» ',
    trail = '·',
    nbsp = '␣',
}

vim.opt.sessionoptions:remove 'blank'

opt.inccommand = 'split'
opt.cursorline = true
opt.scrolloff = 8
opt.confirm = true
opt.termguicolors = true
opt.laststatus = 3
opt.winborder = 'rounded'

opt.statuscolumn = '%s%C%=%{v:relnum == 0 ? v:lnum : v:relnum}   '

-- Four-space defaults. Project-local settings and formatters can override them.
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.shiftround = true

-- Use the system clipboard. Scheduled to avoid delaying startup.
vim.schedule(function() opt.clipboard = 'unnamedplus' end)

vim.g.autoformat = false

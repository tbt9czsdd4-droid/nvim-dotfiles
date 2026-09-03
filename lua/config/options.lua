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

-- Use the system clipboard only in a local session.  Over SSH, OSC52 cannot
-- read the terminal clipboard without querying it, which makes normal `p`
-- wait for a response.  Leaving `clipboard` unset remotely keeps yanks and
-- pastes in Neovim's internal registers instead.
local is_ssh = vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_TTY ~= nil
if not is_ssh then
    -- Scheduled to avoid delaying startup while the clipboard provider loads.
    vim.schedule(function() opt.clipboard = 'unnamedplus' end)
end

vim.g.autoformat = false

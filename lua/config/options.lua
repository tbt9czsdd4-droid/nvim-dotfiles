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

opt.foldenable = false
opt.sessionoptions:remove { 'blank', 'folds' }
-- Saves g:BufferlinePositions, so reordered buffer tabs survive a workspace switch.
opt.sessionoptions:append 'globals'

opt.inccommand = 'split'
opt.cursorline = true
opt.scrolloff = 8
opt.confirm = true
opt.termguicolors = true
opt.laststatus = 3
opt.winborder = 'rounded'
opt.splitkeep = 'screen'
opt.linebreak = true
opt.virtualedit = 'block'

opt.statuscolumn = '%s%C%=%{v:relnum == 0 ? v:lnum : v:relnum}   '

-- Four-space defaults. Project-local settings and formatters can override them.
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.shiftround = true

vim.g.is_ssh = vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_TTY ~= nil

-- Over SSH, send yanks to the client's clipboard with OSC 52, but do not try
-- to read it back: many terminals either forbid clipboard reads or never
-- answer, which makes `p` wait for an OSC 52 response. Pasting returns the
-- last yank made in this Neovim instead. Terminal paste (usually
-- Ctrl-Shift-V) still inserts text copied on the client.
if vim.g.is_ssh then
    local osc52 = require 'vim.ui.clipboard.osc52'
    local last = { {}, 'v' }
    local function copy(register)
        local send = osc52.copy(register)
        return function(lines, regtype)
            last = { lines, regtype }
            send(lines)
        end
    end
    local function paste() return last end

    vim.g.clipboard = {
        name = 'OSC 52',
        copy = {
            ['+'] = copy '+',
            ['*'] = copy '*',
        },
        paste = {
            ['+'] = paste,
            ['*'] = paste,
        },
    }
    opt.clipboard = 'unnamedplus'
else
    -- Scheduled to avoid delaying startup while the clipboard provider loads.
    vim.schedule(function() opt.clipboard = 'unnamedplus' end)
end

vim.g.autoformat = false

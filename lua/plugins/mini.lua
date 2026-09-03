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
        use_as_default_explorer = true,
        lsp_timeout = 0,
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

require('mini.visits').setup()

local diff = require 'mini.diff'
diff.setup {
    view = {
        style = 'sign',
    },
    mappings = {
        apply = '',
        reset = '',
    },
}

vim.keymap.set('n', '<leader>ud', function() diff.toggle_overlay() end, { desc = 'Toggle diff overlay' })

local clue = require 'mini.clue'
clue.setup {
    triggers = {
        { mode = { 'n', 'x' }, keys = '<Leader>' },
        { mode = { 'n', 'x' }, keys = '[' },
        { mode = { 'n', 'x' }, keys = ']' },
        { mode = { 'n', 'x' }, keys = 'g' },
        { mode = { 'n', 'x' }, keys = 'z' },
    },
    clues = {
        { mode = { 'n', 'x' }, keys = '<Leader>b', desc = '+buffer' },
        { mode = { 'n', 'x' }, keys = '<Leader>c', desc = '+code' },
        { mode = { 'n', 'x' }, keys = '<Leader>f', desc = '+file/find' },
        { mode = { 'n', 'x' }, keys = '<Leader>q', desc = '+quit/session' },
        { mode = { 'n', 'x' }, keys = '<Leader>s', desc = '+search' },
        { mode = { 'n', 'x' }, keys = '<Leader>u', desc = '+ui/toggles' },
        clue.gen_clues.square_brackets(),
        clue.gen_clues.g(),
        clue.gen_clues.z(),
    },
    window = {
        delay = 300,
    },
}

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

-- Avoid extra redraw traffic over SSH. Snacks also disables animations
-- buffer-locally whenever its big-file mode is active.
local is_ssh = vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_TTY ~= nil
if is_ssh then return end

local animate = require 'mini.animate'
local max_animated_scroll = 1000

local function should_animate_scroll(total_scroll)
    local mode = vim.api.nvim_get_mode().mode:sub(1, 1)

    -- Animated scrolling can move the cursor between chunks of a bracketed
    -- paste, causing multiline terminal pastes to be inserted out of order.
    if mode == 'i' or mode == 'R' then return false end

    return total_scroll > 1 and total_scroll <= max_animated_scroll
end

animate.setup {
    cursor = {
        enable = true,
        timing = animate.gen_timing.linear { duration = 100, unit = 'total' },
    },
    scroll = {
        enable = true,
        timing = animate.gen_timing.linear { duration = 100, unit = 'total' },
        -- Large jumps require many expensive redraws and can leave `gg`/`G`
        -- partway through the file when the animation is interrupted.
        subscroll = animate.gen_subscroll.equal {
            predicate = should_animate_scroll,
        },
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

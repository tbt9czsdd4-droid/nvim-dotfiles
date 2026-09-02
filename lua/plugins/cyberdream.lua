local is_ssh = vim.env.SSH_CONNECTION ~= nil

require('cyberdream').setup {
    variant = 'default',
    transparent = not is_ssh,
    italic_keywords = false,
    terminal_colors = false,
}

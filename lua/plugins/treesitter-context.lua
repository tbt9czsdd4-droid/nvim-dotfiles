local context = require 'treesitter-context'

-- At most three enclosing headers, one line each.
context.setup { max_lines = 3, multiline_threshold = 1 }

-- Upstream suggests `[c`, which would shadow diff mode's previous change.
vim.keymap.set('n', '[x', function() context.go_to_context(vim.v.count1) end, { desc = 'Go to context' })

local dap = require 'dap'
local dapui = require 'dapui'

dapui.setup()
require('nvim-dap-virtual-text').setup {}

require('mason-nvim-dap').setup {
    ensure_installed = {
        'codelldb',
        'python',
    },
    automatic_installation = true,
    handlers = {},
}

vim.fn.sign_define('DapBreakpoint', {
    text = '●',
    texthl = 'DiagnosticError',
    linehl = '',
    numhl = '',
})
vim.fn.sign_define('DapBreakpointCondition', {
    text = '◆',
    texthl = 'DiagnosticWarn',
    linehl = '',
    numhl = '',
})
vim.fn.sign_define('DapStopped', {
    text = '▶',
    texthl = 'DiagnosticInfo',
    linehl = 'Visual',
    numhl = '',
})

dap.listeners.before.attach.dapui_config = function() dapui.open() end
dap.listeners.before.launch.dapui_config = function() dapui.open() end
dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

local map = vim.keymap.set
map('n', '<F5>', function() dap.continue() end, { desc = 'DAP continue' })
map('n', '<F10>', function() dap.step_over() end, { desc = 'DAP step over' })
map('n', '<F11>', function() dap.step_into() end, { desc = 'DAP step into' })
map('n', '<F12>', function() dap.step_out() end, { desc = 'DAP step out' })
map('n', '<leader>db', function() dap.toggle_breakpoint() end, { desc = 'Toggle breakpoint' })
map('n', '<leader>dB', function() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, { desc = 'Conditional breakpoint' })
map('n', '<leader>dc', function() dap.continue() end, { desc = 'Continue' })
map('n', '<leader>di', function() dap.step_into() end, { desc = 'Step into' })
map('n', '<leader>do', function() dap.step_out() end, { desc = 'Step out' })
map('n', '<leader>dO', function() dap.step_over() end, { desc = 'Step over' })
map('n', '<leader>dr', function() dap.repl.open() end, { desc = 'Open REPL' })
map('n', '<leader>dl', function() dap.run_last() end, { desc = 'Run last' })
map('n', '<leader>dt', function() dap.terminate() end, { desc = 'Terminate' })
map('n', '<leader>du', function() dapui.toggle {} end, { desc = 'Toggle DAP UI' })

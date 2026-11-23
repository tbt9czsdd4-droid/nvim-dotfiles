-- Run with VSG on PATH: nvim --headless -u NONE -i NONE -l tests/vsg.lua
local repo = vim.fn.getcwd()
local temp = vim.fn.tempname()
local project = temp .. '/work project'
local source = project .. '/rtl/sample.vhd'
vim.env.XDG_CONFIG_HOME = temp .. '/config'
vim.env.XDG_STATE_HOME = temp .. '/state'
vim.opt.rtp:prepend(repo)
vim.cmd 'packadd conform.nvim'
vim.g.mapleader = ' '
require 'plugins.conform'

local function write(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    assert(vim.fn.writefile(lines, path) == 0)
end

assert(vim.fn.executable 'vsg' == 1, 'The VHDL integration test requires vsg on PATH')
write(source, { '-- saved file' })
vim.cmd.edit(source)
vim.bo.filetype = 'vhdl'

local input = {
    'ENTITY abc IS',
    'GENERIC(width : POSITIVE := 4);',
    'PORT(i_a : IN STD_LOGIC; o_b : OUT STD_LOGIC_VECTOR(width-1 DOWNTO 0); io_c : INOUT STD_LOGIC);',
    'END ENTITY;',
    'ARCHITECTURE rtl OF abc IS BEGIN',
    'PROCESS(i_a) BEGIN o_b <= (OTHERS => i_a); io_c <= i_a; END PROCESS;',
    'END ARCHITECTURE;',
}
local conform = require 'conform'
local format = conform.format
local finished, failure, notice
conform.format = function(opts, callback)
    return format(opts, function(err, changed)
        callback(err, changed)
        finished, failure = true, err
    end)
end
vim.notify = function(msg) notice = msg end
local function manual(lines)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    finished, failure, notice = false, nil, nil
    vim.fn.maparg(' cf', 'n', false, true).callback()
    assert(vim.wait(10000, function() return finished end), 'VSG timed out')
    assert(vim.deep_equal(vim.fn.readfile(source), { '-- saved file' }))
    return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
end
local function contains(text, pattern) assert(text:match(pattern), pattern .. '\n' .. text) end

local bundled = manual(input)
assert(not failure, failure)
contains(bundled, 'entity ABC is')
contains(bundled, '\n    generic %(\n        WIDTH : positive')
contains(bundled, 'I_A%s*: in%s+std_logic;')
contains(bundled, 'O_B%s*: out%s+std_logic_vector%(WIDTH %- 1 downto 0%)')
contains(bundled, 'IO_C%s*: inout%s+std_logic')
contains(bundled, 'end entity;')
contains(bundled, 'architecture RTL of ABC is')
contains(bundled, '\n    process %(I_A%)')
contains(bundled, 'end process;')
contains(bundled, 'end architecture;')
assert(bundled == manual(vim.split(bundled, '\n')) and not failure)

local bindings = manual {
    'ENTITY abc IS PORT(i_a : IN BOOLEAN); END ENTITY;',
    'ARCHITECTURE rtl OF abc IS',
    'TYPE state_t IS (idle, running); SIGNAL state : STATE_T;',
    'BEGIN',
    'named: PROCESS(i_a) BEGIN ASSERT NOT i_a REPORT "NOT"; END PROCESS named;',
    'u: ENTITY work.child(impl) GENERIC MAP(width => 4) PORT MAP(i_a => i_a);',
    'END ARCHITECTURE rtl;',
}
assert(not failure, failure)
contains(bindings, 'type state_t is')
contains(bindings, 'signal STATE%s*: state_t;')
contains(bindings, 'named : process')
contains(bindings, 'end process named;')
contains(bindings, 'not I_A')
contains(bindings, '"NOT"')
contains(bindings, 'entity WORK%.CHILD%(IMPL%)')
contains(bindings, 'WIDTH => 4')
contains(bindings, 'I_A =>')
contains(bindings, 'end architecture RTL;')

local enum = manual {
    "PACKAGE flags IS TYPE flag_t IS (idle, 'a', 'A');",
    "CONSTANT flag : flag_t := 'a'; END PACKAGE;",
}
assert(not failure, failure)
contains(enum, "type flag_t is %(IDLE, 'a', 'A'%)")
contains(enum, "FLAG%s*: flag_t := 'a';")
local extended = 'entity \\MiXeD\\ is end entity \\MiXeD\\;'
assert(manual { extended } == extended and failure)
contains(notice, 'case%-sensitive extended identifier')

local global = vim.env.XDG_CONFIG_HOME .. '/vsg/.vsg.yaml'
write(global, { 'rule:', '  global: {indent_size: 3}', '  process_016: {disable: false}' })
local partial = manual(input) -- Missing process label returns 1 after VSG writes fixes.
assert(not failure, failure)
contains(partial, 'entity abc is\n   generic')

local other = project .. '/other.vhd'
write(other, { 'ENTITY other IS END;' })
local local_style = project .. '/.vsg.yaml'
write(local_style, {
    'rule: {global: {indent_size: 2}}',
    'file_list:',
    '  - ' .. other,
    'file_rules:',
    '  - ' .. source .. ':',
    '      rule: {entity_008: {case: upper}}',
})
local configured = manual(input)
assert(not failure, failure)
contains(configured, 'entity ABC is\n  generic')
assert(vim.deep_equal(vim.fn.readfile(other), { 'ENTITY other IS END;' }))

local broken = 'entity is begin end;'
assert(manual { broken } == broken and failure)
contains(notice, 'Unexpected token')
contains(notice, ':ConformInfo')
write(local_style, { 'rule: {no_such_rule: {disable: true}}' })
assert(manual(input) == table.concat(input, '\n') and failure)
contains(notice, 'no_such_rule')

vim.env.PATH = temp .. '/empty-path'
assert(manual(input) == table.concat(input, '\n') and failure)
contains(notice, ':ConformInfo')
print 'VSG formatting checks passed'

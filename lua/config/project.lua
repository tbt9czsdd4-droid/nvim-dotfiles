local M = {}

local root_markers = {
    '.git',
    'Cargo.toml',
    'pyproject.toml',
    'CMakeLists.txt',
    'Makefile',
    'package.json',
}

function M.root()
    local name = vim.api.nvim_buf_get_name(0)
    local start = name ~= '' and vim.fs.dirname(name) or vim.uv.cwd()
    return vim.fs.root(start, root_markers) or vim.uv.cwd()
end

return M

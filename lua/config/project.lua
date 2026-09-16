local M = {}

function M.root()
    local owner = require('config.sessions').owner()
    if owner then return owner end
    local name = vim.api.nvim_buf_get_name(0)
    if vim.bo.buftype == '' and name ~= '' then
        local path = vim.uv.fs_realpath(name) or name
        return vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)
    end
    return vim.fn.getcwd()
end

return M

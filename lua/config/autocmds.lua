local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

local function wipe_directory_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)

      if name ~= '' and vim.fn.isdirectory(name) == 1 then pcall(vim.api.nvim_buf_delete, buf, { force = true }) end
    end
  end
end

vim.api.nvim_create_autocmd('User', {
  pattern = 'PersistenceSavePre',
  callback = wipe_directory_buffers,
  desc = 'Exclude directory buffers from sessions',
})

autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup('kickstart-checktime', { clear = true }),
  callback = function()
    if vim.o.buftype ~= 'nofile' then vim.cmd 'checktime' end
  end,
})

autocmd('BufReadPost', {
  group = augroup('kickstart-last-location', { clear = true }),
  callback = function(event)
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(event.buf)
    if mark[1] > 0 and mark[1] <= line_count then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
  end,
})

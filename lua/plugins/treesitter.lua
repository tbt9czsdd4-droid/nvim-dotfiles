local parsers = {
  "bash",
  "c",
  "cpp",
  "diff",
  "html",
  "json",
  "lua",
  "luadoc",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "rust",
  "toml",
  "vim",
  "vimdoc",
  "vhdl",
  "yaml",
}

local filetypes = {
  "c",
  "cpp",
  "html",
  "json",
  "lua",
  "markdown",
  "python",
  "rust",
  "sh",
  "toml",
  "vim",
  "vhdl",
  "yaml",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local treesitter = require("nvim-treesitter")
      treesitter.setup()
      treesitter.install(parsers)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("kickstart-treesitter", { clear = true }),
        pattern = filetypes,
        callback = function(event)
          pcall(vim.treesitter.start, event.buf)
        end,
      })
    end,
  },
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy  = false,
    config = function()
      vim.defer_fn(function()
        local ok, configs = pcall(require, "nvim-treesitter.configs")
        if ok then
          configs.setup({
            ensure_installed = { "markdown", "markdown_inline", "lua", "vim" },
            highlight        = { enable = true },
            indent           = { enable = true },
          })
        end
      end, 100)
    end,
  },
}

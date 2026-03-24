return {
  {
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<C-l>",
          clear_suggestion  = "<C-]>",
          accept_word       = "<C-j>",
        },
        ignore_filetypes = {},
        color = {
          suggestion_color = "#565f89",
          cterm            = 244,
        },
        log_level          = "off",
        disable_inline_completion = false,
        disable_keymaps           = false,
      })
    end,
  },
}

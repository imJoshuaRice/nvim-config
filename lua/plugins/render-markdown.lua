return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("render-markdown").setup({
        enabled      = true,
        render_modes = { "n", "c" },
        heading  = { enabled = true, sign = false, icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " } },
        checkbox = { enabled = true, unchecked = { icon = "󰄱 " }, checked = { icon = "󰱒 " } },
        bullet   = { enabled = true, icons = { "●", "○", "◆", "◇" } },
        code     = { enabled = true, sign = false, style = "full" },
      })
    end,
  },
}

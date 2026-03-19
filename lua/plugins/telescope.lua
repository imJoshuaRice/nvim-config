return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local telescope = require("telescope")
      local builtin   = require("telescope.builtin")
      local notes     = (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes"

      telescope.setup({
        defaults = {
          path_display         = { "smart" },
          file_ignore_patterns = {
            "%.git[\\/]",
            "%.git$",
            "node_modules[\\/]",
            "%.pdf$",
            "%.docx$",
            "%.xlsx$",
          },
          preview = {
            treesitter = false,
          },
        },
      })

      vim.keymap.set("n", "<leader>sf", function()
        builtin.find_files({ cwd = notes, hidden = false })
      end, { desc = "Search note filenames" })

      vim.keymap.set("n", "<leader>sg", function()
        builtin.live_grep({ cwd = notes })
      end, { desc = "Grep search all notes" })

      vim.keymap.set("n", "<leader>sp", function()
        builtin.live_grep({ cwd = notes .. "\\projects" })
      end, { desc = "Search within projects" })
    end,
  },
}

return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      vim.g.loaded_netrw       = 1
      vim.g.loaded_netrwPlugin = 1

      local notes_root = (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes"

      require("nvim-tree").setup({
        sort_by = "name",
        sync_root_with_cwd   = false,
        respect_buf_cwd      = false,
        prefer_startup_root  = false,
        view = {
          width = 35,
          side  = "left",
        },
        renderer = {
          group_empty = true,
          icons = {
            show = {
              file         = true,
              folder       = true,
              folder_arrow = true,
            },
          },
        },
        filters = {
          dotfiles = true,
          custom   = { ".git", "node_modules" },
        },
        actions = {
          open_file = {
            quit_on_open  = false,
            window_picker = { enable = false },
          },
        },
      })

      -- Always open tree rooted at notes vault
      vim.keymap.set("n", "<leader>e", function()
        require("nvim-tree.api").tree.toggle({ path = notes_root })
      end, { desc = "Toggle file explorer" })

      vim.keymap.set("n", "<leader>ef", function()
        require("nvim-tree.api").tree.open({ path = notes_root })
        require("nvim-tree.api").tree.focus()
      end, { desc = "Focus file explorer" })
    end,
  },
}

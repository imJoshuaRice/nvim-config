return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      local notes_root = (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes"

      require("neo-tree").setup({
        close_if_last_window = false,
        popup_border_style   = "rounded",
        enable_git_status    = true,
        enable_diagnostics   = false,
        default_component_configs = {
          indent = {
            indent_size        = 2,
            padding            = 1,
            with_markers       = true,
            indent_marker      = "|",
            last_indent_marker = "L",
          },
          icon = {
            folder_closed = "",
            folder_open   = "",
            folder_empty  = "",
          },
          git_status = {
            symbols = {
              added     = "",
              modified  = "",
              deleted   = "x",
              renamed   = "r",
              untracked = "?",
              ignored   = "",
              unstaged  = "m",
              staged    = "s",
              conflict  = "!",
            },
          },
        },
        window = {
          position = "left",
          width    = 35,
          mappings = {
            ["<space>"] = "none",
            ["/"]       = "fuzzy_finder",
            ["#"]       = "fuzzy_finder_directory",
            ["f"]       = "filter_on_submit",
            ["<esc>"]   = "clear_filter",
          },
        },
        filesystem = {
          filtered_items = {
            visible        = false,
            hide_dotfiles  = true,
            hide_gitignored = true,
            hide_by_name   = { ".git" },
          },
          follow_current_file = {
            enabled = true,
          },
          use_libuv_file_watcher = true,
        },
      })

      -- Always open rooted at notes vault
      vim.keymap.set("n", "<leader>e", function()
        require("neo-tree.command").execute({
          action = "focus",
          source = "filesystem",
          position = "left",
          dir = notes_root,
        })
      end, { desc = "Toggle file explorer" })

      vim.keymap.set("n", "<leader>ef", function()
        require("neo-tree.command").execute({
          action = "show",
          source = "filesystem",
          position = "left",
          dir = notes_root,
        })
      end, { desc = "Focus file explorer" })
    end,
  },
}

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
          preview = { treesitter = false },
        },
      })

      vim.keymap.set("n", "<leader>sf", function()
        builtin.find_files({ cwd = notes, hidden = false })
      end, { desc = "Search note filenames" })

      vim.keymap.set("n", "<leader>sg", function()
        builtin.live_grep({
          cwd = notes,
          attach_mappings = function(_, map)
            map("i", "<CR>", function(prompt_bufnr)
              local action_state = require("telescope.actions.state")
              local actions      = require("telescope.actions")
              local entry        = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              if entry and entry.filename then
                local filepath = entry.filename
                if not filepath:match("^[A-Za-z]:") then
                  filepath = notes .. "\\" .. filepath
                end
                vim.cmd("edit " .. vim.fn.fnameescape(filepath))
                if entry.lnum then
                  vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col or 0 })
                end
              end
            end)
            return true
          end,
        })
      end, { desc = "Grep search all notes" })

      vim.keymap.set("n", "<leader>sp", function()
        builtin.live_grep({
          cwd = notes .. "\\projects",
          attach_mappings = function(_, map)
            map("i", "<CR>", function(prompt_bufnr)
              local action_state = require("telescope.actions.state")
              local actions      = require("telescope.actions")
              local entry        = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              if entry and entry.filename then
                local filepath = entry.filename
                if not filepath:match("^[A-Za-z]:") then
                  filepath = notes .. "\\projects\\" .. filepath
                end
                vim.cmd("edit " .. vim.fn.fnameescape(filepath))
                if entry.lnum then
                  vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col or 0 })
                end
              end
            end)
            return true
          end,
        })
      end, { desc = "Search within projects" })
    end,
  },
}

return {
  {
    "jakewvincent/mkdnflow.nvim",
    config = function()
      require("mkdnflow").setup({
        modules = {
          bib     = false,
          buffers = true,
          conceal = true,
          cursor  = true,
          folds   = false,
          links   = true,
          lists   = true,
          maps    = true,
          paths   = true,
          tables  = true,
        },
        filetypes   = { markdown = true },
        create_dirs = true,
        perspective = {
          priority     = "first",
          fallback     = "current",
          root_tell    = false,
          nvim_wd_heel = false,
        },
        links = {
          style              = "wiki",
          name_is_source     = false,
          conceal            = false,
          context            = 0,
          implicit_extension = nil,
          transform_implicit = false,
          transform_explicit = function(text)
            text = text:gsub(" ", "-")
            text = text:lower()
            return text
          end,
        },
        new_file_template = { use_template = false },
        to_do = {
          statuses = {
            not_started = { marker = " " },
            in_progress = { marker = "-" },
            complete    = { marker = "X" },
          },
          status_order       = { "not_started", "in_progress", "complete" },
          status_propagation = { up = true, down = false },
        },
        tables   = { trim_whitespace = true, format_on_move = true },
        mappings = {
          MkdnEnter   = false,
          MkdnGoBack  = false,
        },
      })

      -- Use our custom resolver for Enter and Backspace in all markdown buffers
      vim.api.nvim_create_autocmd("FileType", {
        pattern  = "markdown",
        callback = function()
          vim.keymap.set("n", "<CR>", function()
            require("notes.resolver").follow_link()
          end, { buffer = true, silent = true, desc = "Follow wikilink" })
          vim.keymap.set("n", "<BS>", function()
            require("notes.resolver").go_back()
          end, { buffer = true, silent = true, desc = "Go back" })
        end,
      })
    end,
  },
}

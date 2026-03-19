return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {},
    config = function()
      local cmp = require("cmp")

      require("cmp").register_source("notes", require("notes.cmp_source"))

      cmp.setup({
        sources = cmp.config.sources({
          { name = "notes" },
        }),
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"]     = cmp.mapping.select_next_item(),
          ["<S-Tab>"]   = cmp.mapping.select_prev_item(),
          ["<C-e>"]     = cmp.mapping.abort(),
        }),
        window = {
          completion    = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        formatting = {
          format = function(entry, vim_item)
            vim_item.menu = "[notes]"
            return vim_item
          end,
        },
        -- Show all items, do not filter by typed text
        matching = {
          disallow_fuzzy_matching   = false,
          disallow_partial_matching = false,
          disallow_prefix_matching  = false,
        },
      })

      -- Trigger completion automatically after [[
      vim.api.nvim_create_autocmd("TextChangedI", {
        pattern  = "*.md",
        callback = function()
          local row    = vim.api.nvim_win_get_cursor(0)[1]
          local col    = vim.api.nvim_win_get_cursor(0)[2]
          local line   = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
          local before = line:sub(1, col)
          if before:match("%[%[$") then
            cmp.complete()
          end
        end,
      })
    end,
  },
}

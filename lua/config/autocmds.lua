local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local markdown_group = augroup("MarkdownSettings", { clear = true })
autocmd("FileType", {
  group   = markdown_group,
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap        = true
    vim.opt_local.linebreak   = true
    vim.opt_local.spell       = true
    vim.opt_local.spelllang   = "en_gb"
    vim.opt_local.conceallevel = 2
  end,
})

local dashboard_group = augroup("DashboardAutoOpen", { clear = true })
autocmd("UIEnter", {
  group    = dashboard_group,
  once     = true,
  callback = function()
    vim.schedule(function()
      local buf        = vim.api.nvim_get_current_buf()
      local name       = vim.api.nvim_buf_get_name(buf)
      local line_count = vim.api.nvim_buf_line_count(buf)
      if name == "" and line_count <= 1 then
        local ok, err = pcall(function()
          require("notes.dashboard").open()
        end)
        if not ok then
          print("Dashboard error: " .. tostring(err))
        end
      end
    end)
  end,
})

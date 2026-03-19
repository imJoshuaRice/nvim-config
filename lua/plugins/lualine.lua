return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local notes_root = (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes"

      -- Show note type from frontmatter if in notes vault
      local function note_type()
        local path = vim.fn.expand("%:p")
        if not path:find(notes_root, 1, true) then return "" end
        local f = io.open(path, "r")
        if not f then return "" end
        local count = 0
        for line in f:lines() do
          count = count + 1
          local t = line:match("^type:%s*(.+)")
          if t then f:close(); return "[" .. t .. "]" end
          if count > 10 then break end
        end
        f:close()
        return ""
      end

      -- Show task count from tasks.md
      local function task_count()
        local path = notes_root .. "\\tasks.md"
        local f = io.open(path, "r")
        if not f then return "" end
        local count = 0
        for line in f:lines() do
          if line:match("^%s*%- %[ %]") then count = count + 1 end
        end
        f:close()
        if count == 0 then return "" end
        return "tasks:" .. count
      end

      require("lualine").setup({
        options = {
          theme                = "tokyonight",
          component_separators = { left = "|", right = "|" },
          section_separators   = { left = "", right = "" },
          globalstatus         = true,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { { "filename", path = 1 } },
          lualine_c = { note_type },
          lualine_x = { task_count, "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },
}

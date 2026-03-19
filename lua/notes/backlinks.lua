local M = {}

local function notes_root()
  return (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes"
end

-- Get the filename stem of the current buffer
local function current_stem()
  return vim.fn.fnamemodify(vim.fn.expand("%:p"), ":t:r")
end

-- Get the title from a file's frontmatter or first heading
local function get_title(filepath)
  local f = io.open(filepath, "r")
  if not f then return nil end
  local in_frontmatter = false
  local checked_first  = false
  local title          = nil
  local heading        = nil
  local count          = 0
  for line in f:lines() do
    count = count + 1
    if not checked_first then
      checked_first = true
      if line:match("^---") then in_frontmatter = true end
    elseif in_frontmatter then
      if line:match("^---") then
        in_frontmatter = false
      else
        local t = line:match("^title:%s*(.+)")
        if t then title = t:gsub('"', ''):gsub("'", "") end
      end
    else
      local h = line:match("^#%s+(.+)")
      if h then heading = h; break end
    end
    if count > 30 then break end
  end
  f:close()
  return title or heading
end

-- Search all notes for links to the current file
local function find_backlinks(stem)
  local root    = notes_root()
  local files   = vim.fn.globpath(root, "**/*.md", false, true)
  local results = {}

  for _, filepath in ipairs(files) do
    local f = io.open(filepath, "r")
    if f then
      local line_num = 0
      for line in f:lines() do
        line_num = line_num + 1
        if line:match("%[%[" .. vim.pesc(stem) .. "%]%]") then
          table.insert(results, {
            filepath = filepath,
            line_num = line_num,
            line     = line:gsub("^%s+", ""),
            title    = get_title(filepath) or vim.fn.fnamemodify(filepath, ":t:r"),
          })
        end
      end
      f:close()
    end
  end

  return results
end

function M.show()
  local stem = current_stem()
  if stem == "" then print("No file open"); return end

  local backlinks = find_backlinks(stem)

  local display_lines = {}
  local link_map      = {}  -- display row ? backlink entry

  table.insert(display_lines, "  Backlinks for: " .. stem)
  table.insert(display_lines, "  | Enter:jump  q/Esc:close")
  table.insert(display_lines, "  " .. string.rep("-", 50))

  if #backlinks == 0 then
    table.insert(display_lines, "")
    table.insert(display_lines, "  No backlinks found.")
    table.insert(display_lines, "")
  else
    local last_title = nil
    for _, bl in ipairs(backlinks) do
      -- Group by source file
      if bl.title ~= last_title then
        table.insert(display_lines, "")
        table.insert(display_lines, "  " .. bl.title)
        last_title = bl.title
      end
      local display = "    > " .. bl.line
      table.insert(display_lines, display)
      link_map[#display_lines] = bl
    end
    table.insert(display_lines, "")
  end

  local buf    = vim.api.nvim_create_buf(false, true)
  local width  = math.floor(vim.o.columns * 0.7)
  local height = math.min(#display_lines + 2, math.floor(vim.o.lines * 0.6))

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

  local win = vim.api.nvim_open_win(buf, true, {
    relative  = "editor",
    width     = width,
    height    = height,
    row       = math.floor((vim.o.lines - height) / 2),
    col       = math.floor((vim.o.columns - width) / 2),
    style     = "minimal",
    border    = "rounded",
    title     = " Backlinks ",
    title_pos = "center",
  })

  -- Jump to source file at the linking line
  vim.keymap.set("n", "<CR>", function()
    local row = vim.api.nvim_win_get_cursor(win)[1]
    local bl  = link_map[row]
    if not bl then return end
    vim.api.nvim_win_close(win, true)
    vim.cmd("edit " .. vim.fn.fnameescape(bl.filepath))
    vim.api.nvim_win_set_cursor(0, { bl.line_num, 0 })
    vim.cmd("normal! zz")
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "q",     function() vim.api.nvim_win_close(win, true) end, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", function() vim.api.nvim_win_close(win, true) end, { buffer = buf, silent = true })
end

return M

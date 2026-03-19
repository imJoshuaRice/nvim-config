local source = {}

local function notes_root()
  return (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes"
end

local function get_title(filepath)
  local f = io.open(filepath, "r")
  if not f then return nil end
  local in_frontmatter = false
  local checked_first  = false
  local title          = nil
  local heading        = nil
  local line_count     = 0

  for line in f:lines() do
    line_count = line_count + 1

    -- Check for frontmatter start
    if not checked_first then
      checked_first = true
      if line:match("^---") then
        in_frontmatter = true
      end
    elseif in_frontmatter then
      if line:match("^---") then
        in_frontmatter = false
      else
        local t = line:match("^title:%s*(.+)")
        if t then title = t:gsub('"', ''):gsub("'", "") end
      end
    else
      -- Look for first # heading outside frontmatter
      local h = line:match("^#%s+(.+)")
      if h then heading = h; break end
    end

    if line_count > 30 then break end
  end
  f:close()
  return title or heading
end

local function stem(filepath)
  return vim.fn.fnamemodify(filepath, ":t:r")
end

local function get_items()
  local root  = notes_root()
  local files = vim.fn.globpath(root, "**/*.md", false, true)
  local items = {}
  for _, filepath in ipairs(files) do
    local filename = stem(filepath)
    local title    = get_title(filepath) or filename
    table.insert(items, {
      label      = title,
      filterText = title,
      sortText   = title,
      insertText = filename,
      kind       = 17,
      data       = { filepath = filepath },
    })
  end
  return items
end

function source:is_available()
  return vim.bo.filetype == "markdown"
end

function source:get_debug_name()
  return "notes"
end

function source:get_keyword_pattern()
  return [[\w\+]]
end

function source:complete(request, callback)
  local row    = vim.api.nvim_win_get_cursor(0)[1]
  local col    = vim.api.nvim_win_get_cursor(0)[2]
  local line   = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
  local before = line:sub(1, col)

  if not before:match("%[%[") then
    callback({ items = {}, isIncomplete = false })
    return
  end

  callback({ items = get_items(), isIncomplete = true })
end

function source:resolve(item, callback)
  callback(item)
end

function source:execute(item, callback)
  callback()
end

return source

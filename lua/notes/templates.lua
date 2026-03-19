local M = {}

local function date() return os.date("%Y-%m-%d") end
local function timestamp() return os.date("%Y%m%d%H%M%S") end
local function notes_root()
  return (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes"
end

local function apply_template(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.cmd("normal! G")
end

local function create_note(filepath, template_lines)
  local dir = vim.fn.fnamemodify(filepath, ":h")
  vim.fn.mkdir(dir, "p")
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
  if vim.fn.filereadable(filepath) == 0 or vim.fn.getfsize(filepath) == 0 then
    apply_template(template_lines)
  end
end

local function fleeting_template(slug)
  return {
    "---", "type: fleeting", "title: " .. slug:gsub("-", " "),
    "date: " .. date(), "tags: []", "---", "", "# " .. slug:gsub("-", " "), "",
  }
end

local function literature_template(source)
  return {
    "---", "type: literature", "date: " .. date(), "source: " .. source,
    "author: ", "tags: []", "---", "", "# " .. source, "",
    "## Summary", "", "## Key Ideas", "", "## Quotes", "", "## My Thoughts", "",
  }
end

local function permanent_template(title, id)
  return {
    "---", "type: permanent", "id: " .. id, "title: " .. title,
    "date: " .. date(), "tags: []", "links: []", "---", "", "# " .. title, "",
  }
end

function M.new_fleeting()
  local slug = vim.fn.input("Fleeting note title: ")
  if slug == "" then return end
  slug = slug:gsub(" ", "-"):lower()
  create_note(notes_root() .. "\\zettelkasten\\fleeting\\" .. date() .. "-" .. slug .. ".md", fleeting_template(slug))
end

function M.new_literature()
  local source = vim.fn.input("Source title: ")
  if source == "" then return end
  local slug = source:gsub(" ", "-"):lower()
  create_note(notes_root() .. "\\zettelkasten\\literature\\" .. date() .. "-" .. slug .. ".md", literature_template(source))
end

function M.new_permanent()
  local title = vim.fn.input("Note title: ")
  if title == "" then return end
  local id = timestamp()
  create_note(notes_root() .. "\\zettelkasten\\permanent\\" .. id .. ".md", permanent_template(title, id))
end

function M.new_project()
  local title = vim.fn.input("Project name: ")
  if title == "" then return end
  local slug = title:gsub(" ", "-"):lower()
  create_note(notes_root() .. "\\projects\\" .. slug .. ".md", {
    "---", "type: project", "title: " .. title, "status: active",
    "created: " .. date(), "---", "", "# " .. title, "",
    "## Goal", "", "## Context", "", "## Notes & Links", "",
  })
end

function M.new_area()
  local title = vim.fn.input("Area name: ")
  if title == "" then return end
  local slug = title:gsub(" ", "-"):lower()
  create_note(notes_root() .. "\\areas\\" .. slug .. ".md", {
    "---", "type: area", "title: " .. title, "updated: " .. date(), "---", "",
    "# " .. title, "", "## Overview", "", "## Notes", "", "## Related Areas", "",
  })
end

function M.new_fleeting_named(slug)
  slug = slug:gsub(" ", "-"):lower()
  create_note(notes_root() .. "\\zettelkasten\\fleeting\\" .. date() .. "-" .. slug .. ".md", fleeting_template(slug))
end

function M.new_literature_named(source)
  local slug = source:gsub(" ", "-"):lower()
  create_note(notes_root() .. "\\zettelkasten\\literature\\" .. date() .. "-" .. slug .. ".md", literature_template(source))
end

function M.new_permanent_named(title)
  local id = timestamp()
  create_note(notes_root() .. "\\zettelkasten\\permanent\\" .. id .. ".md", permanent_template(title, id))
end

-- PROMOTE: fleeting ? permanent
function M.promote_to_permanent()
  local current_path = vim.fn.expand("%:p")
  local current_type = ""

  -- Check this is a fleeting note
  local f = io.open(current_path, "r")
  if not f then print("No file open"); return end
  local count = 0
  for line in f:lines() do
    count = count + 1
    local t = line:match("^type:%s*(.+)")
    if t then current_type = t:gsub("%s+", ""); break end
    if count > 10 then break end
  end
  f:close()

  if current_type ~= "fleeting" then
    print("Promote only works on fleeting notes (this is: " .. current_type .. ")")
    return
  end

  -- Get title for the permanent note
  local title = vim.fn.input("Permanent note title: ")
  if title == "" then return end

  -- Read current buffer content (skip frontmatter)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = {}
  local in_frontmatter = false
  local past_frontmatter = false
  for _, line in ipairs(lines) do
    if not past_frontmatter then
      if line:match("^---") and not in_frontmatter then
        in_frontmatter = true
      elseif line:match("^---") and in_frontmatter then
        past_frontmatter = true
      end
    else
      table.insert(content, line)
    end
  end

  -- Create permanent note
  local id       = timestamp()
  local filepath = notes_root() .. "\\zettelkasten\\permanent\\" .. id .. ".md"
  local dir      = vim.fn.fnamemodify(filepath, ":h")
  vim.fn.mkdir(dir, "p")

  -- Build the new file content
  local new_lines = {
    "---",
    "type: permanent",
    "id: " .. id,
    "title: " .. title,
    "date: " .. date(),
    "tags: []",
    "links: []",
    "---",
    "",
    "# " .. title,
    "",
  }

  -- Append the fleeting content (skip the old heading)
  for _, line in ipairs(content) do
    if not line:match("^#%s+") then
      table.insert(new_lines, line)
    end
  end

  -- Write and open the permanent note
  local out = io.open(filepath, "w")
  if out then
    for _, line in ipairs(new_lines) do
      out:write(line .. "\n")
    end
    out:close()
  end

  vim.cmd("edit " .. vim.fn.fnameescape(filepath))

  -- Offer to archive the original fleeting note
  local choice = vim.fn.confirm(
    "Promoted to permanent note. Archive the original fleeting note?",
    "&Yes\n&No", 1
  )
  if choice == 1 then
    local filename    = vim.fn.fnamemodify(current_path, ":t")
    local archive_path = notes_root() .. "\\archive\\" .. filename
    vim.fn.mkdir(notes_root() .. "\\archive", "p")
    vim.fn.rename(current_path, archive_path)
    print("Fleeting note archived.")
  end
end

function M.archive_note()
  local current  = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  if filename == "" then print("No file open"); return end
  local archive_path = notes_root() .. "\\archive\\" .. filename
  vim.fn.mkdir(notes_root() .. "\\archive", "p")
  vim.cmd("silent! write")
  vim.cmd("bdelete")
  vim.fn.rename(current, archive_path)
  print("Archived: " .. filename)
end

return M

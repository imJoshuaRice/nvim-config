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

-- Parse frontmatter from a list of lines
-- Returns a table of key/value pairs and the line index where frontmatter ends
local function parse_frontmatter(lines)
  local fm = {}
  local end_line = 0
  if not lines[1] or not lines[1]:match("^---") then
    return fm, 0
  end
  for i = 2, #lines do
    if lines[i]:match("^---") then
      end_line = i
      break
    end
    local k, v = lines[i]:match("^([%w_]+):%s*(.+)")
    if k then fm[k] = v end
  end
  return fm, end_line
end

-- PROMOTE: fleeting ? permanent
function M.promote_to_permanent()
  local current_path = vim.fn.expand("%:p")

  -- Read current buffer lines
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local fm, fm_end = parse_frontmatter(lines)

  -- Check this is a fleeting note
  local current_type = fm["type"] or ""
  if current_type ~= "fleeting" then
    print("Promote only works on fleeting notes (this is: " .. current_type .. ")")
    return
  end

  -- Get title for the permanent note
  local title = vim.fn.input("Permanent note title: ")
  if title == "" then return end

  -- Collect body content (everything after frontmatter, skip old heading)
  local content = {}
  for i = fm_end + 1, #lines do
    if not lines[i]:match("^#%s+") then
      table.insert(content, lines[i])
    end
  end

  -- Build new frontmatter — carry over tags and public flag if present
  local id = timestamp()
  local new_lines = { "---" }
  table.insert(new_lines, "type: permanent")
  table.insert(new_lines, "id: " .. id)
  table.insert(new_lines, "title: " .. title)
  table.insert(new_lines, "date: " .. date())
  table.insert(new_lines, "tags: " .. (fm["tags"] or "[]"))
  table.insert(new_lines, "links: []")
  -- Carry over public flag if present
  if fm["public"] then
    table.insert(new_lines, "public: " .. fm["public"])
  end
  table.insert(new_lines, "---")
  table.insert(new_lines, "")
  table.insert(new_lines, "# " .. title)
  table.insert(new_lines, "")

  -- Append body content
  for _, line in ipairs(content) do
    table.insert(new_lines, line)
  end

  -- Write permanent note
  local filepath = notes_root() .. "\\zettelkasten\\permanent\\" .. id .. ".md"
  vim.fn.mkdir(vim.fn.fnamemodify(filepath, ":h"), "p")
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
    local filename     = vim.fn.fnamemodify(current_path, ":t")
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

function M.new_literature_from_url()
  local url = vim.fn.input("URL: ")
  if url == "" then return end

  print("Fetching title...")

  local scripts = (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\AppData\\Local\\nvim\\scripts\\"
  local title   = vim.fn.system("powershell -NonInteractive -NoProfile -File " ..
    scripts .. "fetch-title.ps1 -url \"" .. url .. "\"")
  title = title:gsub("%s+$", "")  -- trim trailing whitespace

  if title == "" then
    title = vim.fn.input("Could not fetch title. Enter manually: ")
    if title == "" then return end
  else
    local confirmed = vim.fn.input("Title: " .. title .. "  [Enter to confirm or type new title]: ")
    if confirmed ~= "" then title = confirmed end
  end

  local slug     = title:gsub(" ", "-"):lower():gsub("[^%w%-]", "")
  local filepath = notes_root() .. "\\zettelkasten\\literature\\" .. date() .. "-" .. slug .. ".md"

  create_note(filepath, {
    "---",
    "type: literature",
    "date: " .. date(),
    "source: " .. title,
    "url: " .. url,
    "author: ",
    "tags: []",
    "---",
    "",
    "# " .. title,
    "",
    "## Summary",
    "",
    "## Key Ideas",
    "",
    "## Quotes",
    "",
    "## My Thoughts",
    "",
  })
end

return M

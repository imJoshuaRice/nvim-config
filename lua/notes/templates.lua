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
    "---",
    "type: fleeting",
    "title: " .. slug:gsub("-", " "),
    "date: " .. date(),
    "tags: []",
    "---",
    "",
    "# " .. slug:gsub("-", " "),
    "",
  }
end

local function literature_template(source)
  return {
    "---", "type: literature", "date: " .. date(), "source: " .. source, "author: ", "tags: []", "---", "",
    "# " .. source, "", "## Summary", "", "## Key Ideas", "", "## Quotes", "", "## My Thoughts", "",
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
    "---", "type: project", "title: " .. title, "status: active", "created: " .. date(), "---", "",
    "# " .. title, "", "## Goal", "", "## Context", "", "## Notes & Links", "",
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

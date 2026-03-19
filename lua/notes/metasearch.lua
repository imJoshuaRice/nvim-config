local M = {}

local function notes_root()
  return (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes"
end

-- Parse frontmatter from a file into a key/value table
local function parse_frontmatter(filepath)
  local f = io.open(filepath, "r")
  if not f then return {} end
  local fm          = {}
  local in_fm       = false
  local checked     = false
  local line_count  = 0
  for line in f:lines() do
    line_count = line_count + 1
    if not checked then
      checked = true
      if line:match("^---") then in_fm = true end
    elseif in_fm then
      if line:match("^---") then break end
      local k, v = line:match("^([%w_]+):%s*(.+)")
      if k then fm[k] = v:gsub('"', ''):gsub("'", "") end
    end
    if line_count > 25 then break end
  end
  f:close()
  return fm
end

-- Build display string from frontmatter
local function make_display(fm, filepath)
  local parts = {}
  if fm.type  then table.insert(parts, "[" .. fm.type .. "]") end
  if fm.title then table.insert(parts, fm.title)
  else table.insert(parts, vim.fn.fnamemodify(filepath, ":t:r")) end
  if fm.date  then table.insert(parts, fm.date) end
  if fm.tags  then table.insert(parts, fm.tags) end
  return table.concat(parts, "  ")
end

function M.search(filter_type)
  local pickers      = require("telescope.pickers")
  local finders      = require("telescope.finders")
  local conf         = require("telescope.config").values
  local actions      = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local root  = notes_root()
  local files = vim.fn.globpath(root, "**/*.md", false, true)

  local entries = {}
  for _, filepath in ipairs(files) do
    local fm = parse_frontmatter(filepath)
    -- Apply type filter if provided
    if not filter_type or fm.type == filter_type then
      table.insert(entries, {
        filepath = filepath,
        fm       = fm,
        display  = make_display(fm, filepath),
      })
    end
  end

  -- Sort by date descending
  table.sort(entries, function(a, b)
    local da = a.fm.date or "0000-00-00"
    local db = b.fm.date or "0000-00-00"
    return da > db
  end)

  local title = filter_type and ("Notes: " .. filter_type) or "All Notes"

  pickers.new({}, {
    prompt_title = title,
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value    = entry,
          display  = entry.display,
          ordinal  = entry.display,
          filename = entry.filepath,
        }
      end,
    }),
    sorter    = conf.generic_sorter({}),
    previewer = conf.file_previewer({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local sel = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if sel then
          vim.cmd("edit " .. vim.fn.fnameescape(sel.value.filepath))
        end
      end)
      return true
    end,
  }):find()
end

-- Convenience wrappers for each note type
function M.search_all()        M.search(nil)          end
function M.search_fleeting()   M.search("fleeting")   end
function M.search_literature() M.search("literature") end
function M.search_permanent()  M.search("permanent")  end
function M.search_projects()   M.search("project")    end
function M.search_areas()      M.search("area")       end

return M

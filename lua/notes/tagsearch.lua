local M = {}

local function notes_root()
  return (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes"
end

-- Extract tags from a file's frontmatter
local function get_tags(filepath)
  local f = io.open(filepath, "r")
  if not f then return {} end
  local in_frontmatter = false
  local checked_first  = false
  local tags           = {}
  local count          = 0
  for line in f:lines() do
    count = count + 1
    if not checked_first then
      checked_first = true
      if line:match("^---") then in_frontmatter = true end
    elseif in_frontmatter then
      if line:match("^---") then break end
      -- Handle both inline: tags: [one, two] and list form
      local inline = line:match("^tags:%s*%[(.-)%]")
      if inline then
        for tag in inline:gmatch("[^,%s]+") do
          table.insert(tags, tag)
        end
      end
      local list_tag = line:match("^%s*%-%s*(.+)")
      if list_tag and count > 2 then
        table.insert(tags, list_tag)
      end
    end
    if count > 20 then break end
  end
  f:close()
  return tags
end

-- Get title from frontmatter or first heading
local function get_title(filepath)
  local f = io.open(filepath, "r")
  if not f then return nil end
  local in_frontmatter = false
  local checked_first  = false
  local title          = nil
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
        if t then title = t:gsub('"', ''):gsub("'", ""); break end
      end
    else
      local h = line:match("^#%s+(.+)")
      if h then title = h; break end
    end
    if count > 30 then break end
  end
  f:close()
  return title or vim.fn.fnamemodify(filepath, ":t:r")
end

-- Build a deduplicated list of all tags across the vault
local function collect_all_tags()
  local root    = notes_root()
  local files   = vim.fn.globpath(root, "**/*.md", false, true)
  local tag_map = {}  -- tag ? list of filepaths

  for _, filepath in ipairs(files) do
    local tags = get_tags(filepath)
    for _, tag in ipairs(tags) do
      if not tag_map[tag] then tag_map[tag] = {} end
      table.insert(tag_map[tag], filepath)
    end
  end

  return tag_map
end

function M.search()
  local pickers    = require("telescope.pickers")
  local finders    = require("telescope.finders")
  local conf       = require("telescope.config").values
  local actions    = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local tag_map = collect_all_tags()

  -- Build tag list for first picker
  local tag_list = {}
  for tag, files in pairs(tag_map) do
    table.insert(tag_list, {
      tag   = tag,
      count = #files,
      files = files,
    })
  end

  -- Sort by tag name
  table.sort(tag_list, function(a, b) return a.tag < b.tag end)

  if #tag_list == 0 then
    print("No tags found in vault. Add tags: [] to note frontmatter.")
    return
  end

  -- First picker: choose a tag
  pickers.new({}, {
    prompt_title = "Search by Tag",
    finder = finders.new_table({
      results = tag_list,
      entry_maker = function(entry)
        return {
          value   = entry,
          display = string.format("%-30s  (%d note%s)", entry.tag, entry.count, entry.count == 1 and "" or "s"),
          ordinal = entry.tag,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not selection then return end

        local chosen_tag   = selection.value.tag
        local tagged_files = selection.value.files

        -- Build note list for second picker
        local note_list = {}
        for _, filepath in ipairs(tagged_files) do
          table.insert(note_list, {
            filepath = filepath,
            title    = get_title(filepath),
          })
        end

        -- Second picker: choose a note from that tag
        pickers.new({}, {
          prompt_title = "Notes tagged: " .. chosen_tag,
          finder = finders.new_table({
            results = note_list,
            entry_maker = function(entry)
              return {
                value    = entry,
                display  = entry.title,
                ordinal  = entry.title,
                filename = entry.filepath,
              }
            end,
          }),
          sorter    = conf.generic_sorter({}),
          previewer = conf.file_previewer({}),
          attach_mappings = function(note_bufnr)
            actions.select_default:replace(function()
              local note_selection = action_state.get_selected_entry()
              actions.close(note_bufnr)
              if note_selection then
                vim.cmd("edit " .. vim.fn.fnameescape(note_selection.value.filepath))
              end
            end)
            return true
          end,
        }):find()
      end)
      return true
    end,
  }):find()
end

return M

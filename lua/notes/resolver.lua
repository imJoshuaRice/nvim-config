local M = {}

-- Navigation history stack
local history = {}

local function notes_root()
  return (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes"
end

local function find_note(link_name)
  link_name = link_name:gsub("%[%[", ""):gsub("%]%]", "")
  if not link_name:match("%.md$") then link_name = link_name .. ".md" end
  local results = vim.fn.globpath(notes_root(), "**/" .. link_name, false, true)
  if results and #results > 0 then return results[1] end
  return nil
end

local function get_link_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col  = vim.api.nvim_win_get_cursor(0)[2] + 1
  local pos  = 1
  while true do
    local s, e, link = line:find("%[%[(.-)%]%]", pos)
    if not s then break end
    if col >= s and col <= e then return link end
    pos = e + 1
  end
  return nil
end

function M.follow_link()
  local link = get_link_under_cursor()
  if not link then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
    return
  end

  local filepath = find_note(link)
  if filepath then
    -- Push current file onto history before navigating
    local current = vim.fn.expand("%:p")
    if current ~= "" then
      table.insert(history, current)
    end
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
  else
    local choice = vim.fn.confirm(
      "Note '" .. link .. "' not found. Create it?",
      "&Fleeting\n&Literature\n&Permanent\n&Cancel", 4
    )
    if     choice == 1 then require("notes.templates").new_fleeting_named(link)
    elseif choice == 2 then require("notes.templates").new_literature_named(link)
    elseif choice == 3 then require("notes.templates").new_permanent_named(link)
    end
  end
end

function M.go_back()
  if #history == 0 then
    print("Nothing to go back to")
    return
  end
  local prev = table.remove(history)
  vim.cmd("edit " .. vim.fn.fnameescape(prev))
end

return M

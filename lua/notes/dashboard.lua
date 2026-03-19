local M = {}

local function notes_root()
  return (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes"
end

local function parse_date(d)
  if not d then return nil end
  local y, m, dd = d:match("(%d%d%d%d)-(%d%d)-(%d%d)")
  if y then return tonumber(y .. m .. dd) end
  return nil
end

local function today() return tonumber(os.date("%Y%m%d")) end
local function today_plus(n) return tonumber(os.date("%Y%m%d", os.time() + (n * 86400))) end

local priority_order = { high = 1, medium = 2, low = 3, none = 4 }
local function priority_rank(p) return priority_order[p] or 4 end

local function parse_tasks()
  local tasks = {}
  local f = io.open(notes_root() .. "\\tasks.md", "r")
  if not f then return tasks end
  for line in f:lines() do
    if line:match("^%s*%- %[ %]") then
      local task  = { raw = line }
      local desc  = line:gsub("^%s*%- %[ %] ", "")
      desc = desc:gsub(" @project:%S+", ""):gsub(" @due:%S+", ""):gsub(" !%S+", "")
      task.desc     = desc
      task.project  = line:match("@project:(%S+)") or "inbox"
      task.due      = line:match("@due:(%d%d%d%d%-%d%d%-%d%d)")
      task.due_num  = parse_date(task.due)
      task.priority = line:match("!(%S+)") or "none"
      table.insert(tasks, task)
    end
  end
  f:close()
  return tasks
end

local function sort_by_priority(tasks)
  table.sort(tasks, function(a, b) return priority_rank(a.priority) < priority_rank(b.priority) end)
  return tasks
end

local function format_task(task)
  local pri_icons = { high = "[!!]", medium = "[! ]", low = "[  ]" }
  local pri  = pri_icons[task.priority] or "[  ]"
  local due  = task.due and ("  due:" .. task.due) or ""
  return string.format("    %s  %s%s", pri, task.desc, due)
end

local function divider(char, width)
  return "  " .. string.rep(char, width or 49)
end

local function section_header(icon, title, count)
  return string.format("  %s  %s  (%d)", icon, title, count)
end

local function build_dashboard(tasks)
  local lines = {}
  local t, t7 = today(), today_plus(7)

  table.insert(lines, "")
  table.insert(lines, divider("="))
  table.insert(lines, "")
  table.insert(lines, "       N E O V I M   D A S H B O A R D")
  table.insert(lines, "       " .. os.date("%A, %d %B %Y"))
  table.insert(lines, "")
  table.insert(lines, divider("="))
  table.insert(lines, "")

  local overdue, due_today, due_week, upcoming, no_due = {}, {}, {}, {}, {}
  for _, task in ipairs(tasks) do
    if task.due_num then
      if     task.due_num < t   then table.insert(overdue, task)
      elseif task.due_num == t  then table.insert(due_today, task)
      elseif task.due_num <= t7 then table.insert(due_week, task)
      else                           table.insert(upcoming, task)
      end
    else
      table.insert(no_due, task)
    end
  end

  local function section(icon, title, bucket)
    if #bucket == 0 then return end
    table.insert(lines, section_header(icon, title, #bucket))
    table.insert(lines, divider("-"))
    for _, task in ipairs(sort_by_priority(bucket)) do
      table.insert(lines, format_task(task))
    end
    table.insert(lines, "")
  end

  section("[!]", "OVERDUE",       overdue)
  section("[>]", "DUE TODAY",     due_today)
  section("[~]", "DUE THIS WEEK", due_week)
  section("[.]", "UPCOMING",      upcoming)

  if #no_due > 0 then
    table.insert(lines, section_header("[-]", "NO DUE DATE", #no_due))
    table.insert(lines, divider("-"))
    local by_project, project_order = {}, {}
    for _, task in ipairs(no_due) do
      if not by_project[task.project] then
        by_project[task.project] = {}
        table.insert(project_order, task.project)
      end
      table.insert(by_project[task.project], task)
    end
    for _, project in ipairs(project_order) do
      table.insert(lines, "    @" .. project)
      for _, task in ipairs(sort_by_priority(by_project[project])) do
        table.insert(lines, "  " .. format_task(task))
      end
    end
    table.insert(lines, "")
  end

  if #tasks == 0 then
    table.insert(lines, "    [+]  No open tasks -- enjoy your day!")
    table.insert(lines, "")
  end

  table.insert(lines, divider("="))
  table.insert(lines, "")
  table.insert(lines, "   QUICK ACTIONS")
  table.insert(lines, "   Space ta  add task        Space nf  fleeting note")
  table.insert(lines, "   Space np  permanent        Space db  dashboard")
  table.insert(lines, "   Space gs  sync to git      Space gp  publish notes")
  table.insert(lines, "   Space ?   keybind help")
  table.insert(lines, "")
  table.insert(lines, divider("="))
  table.insert(lines, "")
  return lines
end

function M.open()
  local tasks = parse_tasks()
  local lines = build_dashboard(tasks)

  local buf = nil
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(b):match("Dashboard$") then buf = b; break end
  end
  if not buf then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, "Dashboard")
  end

  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  vim.api.nvim_set_current_buf(buf)

  vim.keymap.set("n", "q",          "<cmd>q<cr>",                                             { buffer = buf, silent = true })
  vim.keymap.set("n", "r",          function() M.open() end,                                  { buffer = buf, silent = true })
  vim.keymap.set("n", "<CR>",       function() end,                                           { buffer = buf, silent = true })
  vim.keymap.set("n", "<leader>ta", function() require("notes.tasks").add_task() end,         { buffer = buf, silent = true })
  vim.keymap.set("n", "<leader>nf", function() require("notes.templates").new_fleeting() end, { buffer = buf, silent = true })
end

return M

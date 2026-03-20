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

local day_art = {
  Monday    = { "  =====================================", "  M  O  N  D  A  Y", "  =====================================" },
  Tuesday   = { "  =========================================", "  T  U  E  S  D  A  Y", "  =========================================" },
  Wednesday = { "  =================================================", "  W  E  D  N  E  S  D  A  Y", "  =================================================" },
  Thursday  = { "  ==========================================", "  T  H  U  R  S  D  A  Y", "  ==========================================" },
  Friday    = { "  =====================================", "  F  R  I  D  A  Y", "  =====================================" },
  Saturday  = { "  ==========================================", "  S  A  T  U  R  D  A  Y", "  ==========================================" },
  Sunday    = { "  =======================================", "  S  U  N  D  A  Y", "  =======================================" },
}

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

local function parse_projects(tasks)
  local root  = notes_root()
  local files = vim.fn.globpath(root .. "\\projects", "*.md", false, true)
  local task_counts = {}
  for _, task in ipairs(tasks) do
    task_counts[task.project] = (task_counts[task.project] or 0) + 1
  end
  local projects = {}
  for _, filepath in ipairs(files) do
    local f = io.open(filepath, "r")
    if f then
      local in_fm = false; local checked = false
      local title = vim.fn.fnamemodify(filepath, ":t:r")
      local status = "active"; local slug = vim.fn.fnamemodify(filepath, ":t:r")
      local lc = 0
      for line in f:lines() do
        lc = lc + 1
        if not checked then checked = true; if line:match("^---") then in_fm = true end
        elseif in_fm then
          if line:match("^---") then break end
          local t = line:match("^title:%s*(.+)"); if t then title = t:gsub('"',''):gsub("'","") end
          local s = line:match("^status:%s*(.+)"); if s then status = s:gsub("%s+","") end
        end
        if lc > 20 then break end
      end
      f:close()
      if status == "active" then
        table.insert(projects, { title = title, slug = slug, task_count = task_counts[slug] or 0 })
      end
    end
  end
  table.sort(projects, function(a, b) return a.title < b.title end)
  return projects
end

local function sort_by_priority(tasks)
  table.sort(tasks, function(a, b) return priority_rank(a.priority) < priority_rank(b.priority) end)
  return tasks
end

local function get_recents()
  local ok, recents = pcall(function() return require("notes.recents").get() end)
  if not ok then return {} end
  return recents
end

local function format_task_line(task, width)
  local pri_icons = { high = "[!!]", medium = "[! ]", low = "[  ]", none = "[  ]" }
  local pri  = pri_icons[task.priority] or "[  ]"
  local due  = task.due and (" " .. task.due) or ""
  local desc = task.desc
  local max_desc = width - #pri - #due - 3
  if #desc > max_desc then desc = desc:sub(1, max_desc - 2) .. ".." end
  return pri .. " " .. desc .. due
end

local function setup_highlights()
  vim.api.nvim_set_hl(0, "DashboardHeader",  { fg = "#7aa2f7", bold = true })
  vim.api.nvim_set_hl(0, "DashboardDate",    { fg = "#9ece6a" })
  vim.api.nvim_set_hl(0, "DashboardStats",   { fg = "#e0af68" })
  vim.api.nvim_set_hl(0, "DashboardBorder",  { fg = "#3b4261" })
  vim.api.nvim_set_hl(0, "DashboardSection", { fg = "#bb9af7", bold = true })
  vim.api.nvim_set_hl(0, "DashboardOverdue", { fg = "#f7768e", bold = true })
  vim.api.nvim_set_hl(0, "DashboardToday",   { fg = "#e0af68", bold = true })
  vim.api.nvim_set_hl(0, "DashboardWeek",    { fg = "#9ece6a" })
  vim.api.nvim_set_hl(0, "DashboardNormal",  { fg = "#a9b1d6" })
  vim.api.nvim_set_hl(0, "DashboardMuted",   { fg = "#565f89" })
  vim.api.nvim_set_hl(0, "DashboardProject", { fg = "#7dcfff" })
  vim.api.nvim_set_hl(0, "DashboardRecent",  { fg = "#73daca" })
  vim.api.nvim_set_hl(0, "DashboardFooter",  { fg = "#565f89" })
  vim.api.nvim_set_hl(0, "DashboardKey",     { fg = "#e0af68", bold = true })
end

local function build_dashboard(tasks, projects, recents)
  local lines  = {}
  local hl_map = {}
  local t, t7  = today(), today_plus(7)

  local function add(line, hl)
    table.insert(lines, line)
    if hl then table.insert(hl_map, { #lines, 0, #line, hl }) end
  end

  local overdue, due_today, due_week, upcoming, no_due = {}, {}, {}, {}, {}
  for _, task in ipairs(tasks) do
    if task.due_num then
      if     task.due_num < t   then table.insert(overdue, task)
      elseif task.due_num == t  then table.insert(due_today, task)
      elseif task.due_num <= t7 then table.insert(due_week, task)
      else                           table.insert(upcoming, task)
      end
    else table.insert(no_due, task)
    end
  end

  local day_name = os.date("%A")
  local art = day_art[day_name] or day_art["Monday"]

  add("", "DashboardBorder")
  for i, art_line in ipairs(art) do
    if i == 2 then
      local padding = string.rep(" ", math.max(2, 54 - #art_line))
      local full_line = art_line .. padding .. os.date("%d %B %Y")
      table.insert(lines, full_line)
      table.insert(hl_map, { #lines, 0, #art_line, "DashboardHeader" })
      table.insert(hl_map, { #lines, #art_line + #padding, #full_line, "DashboardDate" })
    else
      add(art_line, "DashboardBorder")
    end
  end

  local stats = string.format("  %d open task%s    %d active project%s",
    #tasks, (#tasks == 1 and "" or "s"),
    #projects, (#projects == 1 and "" or "s"))
  if #overdue > 0 then stats = stats .. string.format("    %d overdue", #overdue) end
  if #due_today > 0 then stats = stats .. string.format("    %d due today", #due_today) end
  add(stats, "DashboardStats")
  add("", "DashboardBorder")
  add("  " .. string.rep("-", 76), "DashboardBorder")
  add("", "DashboardBorder")

  local col_width   = 46
  local left_lines  = {}
  local right_lines = {}

  table.insert(left_lines,  { "  TASKS",    "DashboardSection" })
  table.insert(left_lines,  { "  " .. string.rep("-", col_width - 2), "DashboardBorder" })
  table.insert(right_lines, { "  PROJECTS", "DashboardSection" })
  table.insert(right_lines, { "  " .. string.rep("-", col_width - 2), "DashboardBorder" })

  local function summary_line(icon, label, count, hl)
    if count > 0 then
      table.insert(left_lines, { string.format("  %s  %-20s %d", icon, label, count), hl })
    end
  end

  summary_line("[!]", "overdue",       #overdue,   "DashboardOverdue")
  summary_line("[>]", "due today",     #due_today, "DashboardToday")
  summary_line("[~]", "due this week", #due_week,  "DashboardWeek")
  summary_line("[.]", "upcoming",      #upcoming,  "DashboardNormal")
  summary_line("[-]", "no due date",   #no_due,    "DashboardMuted")
  table.insert(left_lines, { "", "DashboardNormal" })

  if #overdue > 0 then
    table.insert(left_lines, { "  OVERDUE", "DashboardOverdue" })
    table.insert(left_lines, { "  " .. string.rep("-", col_width - 2), "DashboardBorder" })
    for _, task in ipairs(sort_by_priority(overdue)) do
      table.insert(left_lines, { "  " .. format_task_line(task, col_width), "DashboardOverdue" })
    end
    table.insert(left_lines, { "", "DashboardNormal" })
  end

  if #due_today > 0 then
    table.insert(left_lines, { "  DUE TODAY", "DashboardToday" })
    table.insert(left_lines, { "  " .. string.rep("-", col_width - 2), "DashboardBorder" })
    for _, task in ipairs(sort_by_priority(due_today)) do
      table.insert(left_lines, { "  " .. format_task_line(task, col_width), "DashboardToday" })
    end
    table.insert(left_lines, { "", "DashboardNormal" })
  end

  if #due_week > 0 then
    table.insert(left_lines, { "  DUE THIS WEEK", "DashboardWeek" })
    table.insert(left_lines, { "  " .. string.rep("-", col_width - 2), "DashboardBorder" })
    for _, task in ipairs(sort_by_priority(due_week)) do
      table.insert(left_lines, { "  " .. format_task_line(task, col_width), "DashboardWeek" })
    end
    table.insert(left_lines, { "", "DashboardNormal" })
  end

  if #no_due > 0 then
    table.insert(left_lines, { "  NO DUE DATE", "DashboardMuted" })
    table.insert(left_lines, { "  " .. string.rep("-", col_width - 2), "DashboardBorder" })
    local by_project, project_order = {}, {}
    for _, task in ipairs(no_due) do
      if not by_project[task.project] then
        by_project[task.project] = {}
        table.insert(project_order, task.project)
      end
      table.insert(by_project[task.project], task)
    end
    for _, project in ipairs(project_order) do
      table.insert(left_lines, { "  @" .. project, "DashboardMuted" })
      for _, task in ipairs(sort_by_priority(by_project[project])) do
        local desc = task.desc
        if #desc > col_width - 8 then desc = desc:sub(1, col_width - 10) .. ".." end
        table.insert(left_lines, { "    [  ] " .. desc, "DashboardMuted" })
      end
    end
    table.insert(left_lines, { "", "DashboardNormal" })
  end

  if #projects == 0 then
    table.insert(right_lines, { "  no active projects", "DashboardMuted" })
  else
    for _, project in ipairs(projects) do
      local task_str = project.task_count == 0 and "no tasks"
        or (project.task_count .. " task" .. (project.task_count == 1 and "" or "s"))
      local title = project.title
      if #title > col_width - 14 then title = title:sub(1, col_width - 16) .. ".." end
      table.insert(right_lines, { string.format("  %-32s %s", title, task_str), "DashboardProject" })
    end
  end
  table.insert(right_lines, { "", "DashboardNormal" })
  table.insert(right_lines, { "  RECENT NOTES", "DashboardSection" })
  table.insert(right_lines, { "  " .. string.rep("-", col_width - 2), "DashboardBorder" })
  if #recents == 0 then
    table.insert(right_lines, { "  no recent notes", "DashboardMuted" })
  else
    for _, filepath in ipairs(recents) do
      local name = vim.fn.fnamemodify(filepath, ":t:r")
      if #name > col_width - 4 then name = name:sub(1, col_width - 6) .. ".." end
      table.insert(right_lines, { "  " .. name, "DashboardRecent" })
    end
  end

  local max_lines = math.max(#left_lines, #right_lines)
  local empty     = { string.rep(" ", col_width), "DashboardNormal" }

  for i = 1, max_lines do
    local l = left_lines[i]  or empty
    local r = right_lines[i] or empty
    local padded_left = l[1] .. string.rep(" ", math.max(0, col_width - #l[1]))
    local full_line   = padded_left .. "  " .. r[1]
    table.insert(lines, full_line)
    table.insert(hl_map, { #lines, 0, #padded_left, l[2] })
    table.insert(hl_map, { #lines, #padded_left + 2, #full_line, r[2] })
  end

  add("", "DashboardBorder")
  add("  " .. string.rep("-", 76), "DashboardBorder")
  local footer = "  nf:fleeting  nl:literature  np:permanent  ta:add task  gs:sync  gp:publish  r:refresh  ?:help"
  table.insert(lines, footer)
  local hl_footer = #lines
  local col = 0
  for part in footer:gmatch("[^%s]+") do
    local s = footer:find(part, col + 1, true)
    if s then
      local key, rest = part:match("^([^:]+)(:.+)$")
      if key and rest then
        table.insert(hl_map, { hl_footer, s - 1, s - 1 + #key, "DashboardKey" })
        table.insert(hl_map, { hl_footer, s - 1 + #key, s - 1 + #part, "DashboardFooter" })
      end
      col = s + #part - 1
    end
  end
  add("", "DashboardBorder")
  return lines, hl_map
end

function M.open()
  setup_highlights()
  local tasks    = parse_tasks()
  local projects = parse_projects(tasks)
  local recents  = get_recents()
  local lines, hl_map = build_dashboard(tasks, projects, recents)

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

  local ns = vim.api.nvim_create_namespace("dashboard_hl")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, hl in ipairs(hl_map) do
    local line, col_s, col_e, group = hl[1] - 1, hl[2], hl[3], hl[4]
    pcall(vim.api.nvim_buf_add_highlight, buf, ns, group, line, col_s, col_e)
  end

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

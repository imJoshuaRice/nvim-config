local M = {}

local function notes_root()
  return (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes"
end

local function tasks_path()
  return notes_root() .. "\\tasks.md"
end

function M.add_task()
  local desc = vim.fn.input("Task: ")
  if desc == "" then return end
  local project  = vim.fn.input("Project (blank to skip): ")
  local due      = vim.fn.input("Due date YYYY-MM-DD (blank to skip): ")
  local priority = vim.fn.input("Priority high/medium/low (blank to skip): ")

  local task = "- [ ] " .. desc
  if project ~= "" then task = task .. " @project:" .. project:gsub(" ", "-"):lower() end
  if due ~= ""     then task = task .. " @due:" .. due end
  if priority ~= "" then
    local p = priority:lower()
    if     p == "high"   or p == "h" then task = task .. " !high"
    elseif p == "medium" or p == "m" then task = task .. " !medium"
    elseif p == "low"    or p == "l" then task = task .. " !low"
    end
  end

  local f = io.open(tasks_path(), "a")
  if f then f:write(task .. "\n"); f:close(); print("Task added: " .. task)
  else print("Error: could not open " .. tasks_path())
  end
end

function M.toggle_task()
  local line = vim.api.nvim_get_current_line()
  local new_line
  if     line:match("^%s*%- %[ %]") then new_line = line:gsub("^(%s*%- )%[ %]", "%1[x]", 1)
  elseif line:match("^%s*%- %[x%]") then new_line = line:gsub("^(%s*%- )%[x%]", "%1[ ]", 1)
  else print("No task found on this line"); return
  end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
end

function M.archive_completed()
  local path = tasks_path()
  local active, completed = {}, {}
  local in_archive = false

  local f = io.open(path, "r")
  if not f then print("Could not open " .. path); return end
  for line in f:lines() do
    if line:match("^## Archive") then
      in_archive = true
    elseif in_archive then
      -- Only keep completed tasks in archive
      -- Move any incomplete tasks back to active
      if line:match("^%s*%- %[ %]") then
        table.insert(active, line)
      elseif line:match("^%s*%- %[x%]") then
        table.insert(completed, line)
      end
      -- Skip blank lines and other content in archive (will be regenerated)
    elseif line:match("^%s*%- %[x%]") then
      table.insert(completed, line)
    else
      table.insert(active, line)
    end
  end
  f:close()

  if #completed == 0 then print("No completed tasks to archive."); return end

  local choice = vim.fn.confirm("Archive " .. #completed .. " completed task(s)?", "&Yes\n&No", 2)
  if choice ~= 1 then return end

  local out = io.open(path, "w")
  if not out then print("Could not write " .. path); return end
  for _, line in ipairs(active) do out:write(line .. "\n") end
  out:write("\n## Archive\n\n")
  for _, line in ipairs(completed) do out:write(line .. "\n") end
  out:close()

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf):match("tasks%.md$") then
      vim.api.nvim_buf_call(buf, function() vim.cmd("edit!") end)
    end
  end
  print("Archived " .. #completed .. " completed task(s).")
end

function M.show_tasks()
  local task_lines = {}
  local task_map   = {}

  local f = io.open(tasks_path(), "r")
  if not f then print("Could not open " .. tasks_path()); return end
  local line_num = 0
  for line in f:lines() do
    line_num = line_num + 1
    if line:match("^%s*%- %[ %]") then
      table.insert(task_lines, line)
      task_map[#task_lines] = line_num
    end
  end
  f:close()

  if #task_lines == 0 then print("No open tasks!"); return end

  local buf    = vim.api.nvim_create_buf(false, true)
  local width  = math.floor(vim.o.columns * 0.8)
  local height = math.min(#task_lines + 4, math.floor(vim.o.lines * 0.6))

  local display_lines = {}
  table.insert(display_lines, "  Open Tasks  |  Enter:jump  x:complete  q/Esc:close")
  table.insert(display_lines, "  " .. string.rep("-", width - 4))
  for _, line in ipairs(task_lines) do
    table.insert(display_lines, line)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

  local win = vim.api.nvim_open_win(buf, true, {
    relative  = "editor",
    width     = width,
    height    = height,
    row       = math.floor((vim.o.lines - height) / 2),
    col       = math.floor((vim.o.columns - width) / 2),
    style     = "minimal",
    border    = "rounded",
    title     = " Open Tasks ",
    title_pos = "center",
  })

  local function get_task_index()
    local row = vim.api.nvim_win_get_cursor(win)[1]
    local idx = row - 2
    if idx < 1 or idx > #task_lines then return nil end
    return idx
  end

  vim.keymap.set("n", "<CR>", function()
    local idx = get_task_index()
    if not idx then return end
    local target_line = task_map[idx]
    vim.api.nvim_win_close(win, true)
    vim.cmd("edit " .. vim.fn.fnameescape(tasks_path()))
    vim.api.nvim_win_set_cursor(0, { target_line, 0 })
    vim.cmd("normal! zz")
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "x", function()
    local idx = get_task_index()
    if not idx then return end
    local task_desc = task_lines[idx]:gsub("^%s*%- %[ %] ", ""):gsub(" @%S+", ""):gsub(" !%S+", "")
    local choice = vim.fn.confirm(
      "Complete task: " .. task_desc .. "?",
      "&Yes\n&No", 2
    )
    if choice ~= 1 then return end

    local target_line = task_map[idx]
    local lines = {}
    local f2 = io.open(tasks_path(), "r")
    if not f2 then return end
    local ln = 0
    for line in f2:lines() do
      ln = ln + 1
      if ln == target_line then
        line = line:gsub("^(%s*%- )%[ %]", "%1[x]", 1)
      end
      table.insert(lines, line)
    end
    f2:close()

    local out = io.open(tasks_path(), "w")
    if out then
      for _, line in ipairs(lines) do out:write(line .. "\n") end
      out:close()
    end

    vim.api.nvim_win_close(win, true)
    print("Task completed: " .. task_desc)
    M.show_tasks()
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "q",     function() vim.api.nvim_win_close(win, true) end, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", function() vim.api.nvim_win_close(win, true) end, { buffer = buf, silent = true })
end

return M

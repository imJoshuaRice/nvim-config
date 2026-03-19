local M = {}

local function notes_root()
  return (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes"
end
local function tasks_path() return notes_root() .. "\\tasks.md" end

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

function M.show_tasks()
  local lines = {}
  local f = io.open(tasks_path(), "r")
  if not f then print("Could not open " .. tasks_path()); return end
  for line in f:lines() do
    if line:match("^%s*%- %[ %]") then table.insert(lines, line) end
  end
  f:close()
  if #lines == 0 then print("No open tasks!"); return end

  local buf    = vim.api.nvim_create_buf(false, true)
  local width  = math.floor(vim.o.columns * 0.8)
  local height = math.min(#lines + 2, math.floor(vim.o.lines * 0.6))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  vim.api.nvim_open_win(buf, true, {
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
  vim.keymap.set("n", "q",    "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>","<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<CR>", "<cmd>close<cr>", { buffer = buf, silent = true })
end

return M

local M = {}

local keybinds = {
  {
    category = "NOTE CREATION",
    items = {
      { key = "Space nf",  desc = "New fleeting note" },
      { key = "Space nl",  desc = "New literature note" },
      { key = "Space np",  desc = "New permanent note" },
      { key = "Space nP",  desc = "New project" },
      { key = "Space na",  desc = "New area / Map of Content" },
      { key = "Space npp", desc = "Promote fleeting ? permanent" },
    },
  },
  {
    category = "NAVIGATION",
    items = {
      { key = "Space nt",  desc = "Open tasks.md" },
      { key = "Space db",  desc = "Open dashboard" },
      { key = "Space e",   desc = "Toggle file explorer" },
      { key = "Space ef",  desc = "Focus file explorer" },
      { key = "Space mv",  desc = "Archive current note" },
      { key = "Enter",     desc = "Follow wikilink" },
      { key = "Backspace", desc = "Navigate back" },
      { key = "Space B",   desc = "Show backlinks to current note" },
    },
  },
  {
    category = "SEARCH",
    items = {
      { key = "Space sf",  desc = "Search note filenames (Telescope)" },
      { key = "Space sg",  desc = "Grep all notes (Telescope)" },
      { key = "Space sp",  desc = "Grep within projects (Telescope)" },
    },
  },
  {
    category = "TASKS",
    items = {
      { key = "Space ta",  desc = "Add task" },
      { key = "Space tt",  desc = "Toggle task complete / incomplete" },
      { key = "Space to",  desc = "Show open tasks (floating window)" },
    },
  },
  {
    category = "GIT SYNC",
    items = {
      { key = "Space gs",  desc = "Sync all to GitHub (notes + config)" },
      { key = "Space gp",  desc = "Publish public: true notes" },
    },
  },
  {
    category = "WIKILINKS",
    items = {
      { key = "[[",        desc = "Trigger note autocomplete dropdown" },
      { key = "Tab",       desc = "Next autocomplete item" },
      { key = "S-Tab",     desc = "Previous autocomplete item" },
      { key = "Enter",     desc = "Confirm autocomplete selection" },
      { key = "Ctrl-e",    desc = "Dismiss autocomplete" },
    },
  },
  {
    category = "FILE EXPLORER",
    items = {
      { key = "a",         desc = "Create new file" },
      { key = "d",         desc = "Delete file" },
      { key = "r",         desc = "Rename file" },
      { key = "R",         desc = "Refresh tree" },
      { key = "?",         desc = "Show all nvim-tree keybinds" },
    },
  },
  {
    category = "DASHBOARD",
    items = {
      { key = "r",         desc = "Refresh dashboard" },
      { key = "q",         desc = "Close dashboard" },
    },
  },
  {
    category = "GENERAL",
    items = {
      { key = "Space w",   desc = "Save file" },
      { key = "Space q",   desc = "Quit" },
      { key = "Space ?",   desc = "Open this cheatsheet" },
    },
  },
}

function M.open()
  local lines = {}

  table.insert(lines, "")
  table.insert(lines, "  ------------------------------------------------------")
  table.insert(lines, "        K E Y B I N D   C H E A T S H E E T")
  table.insert(lines, "  ------------------------------------------------------")
  table.insert(lines, "")

  for _, section in ipairs(keybinds) do
    table.insert(lines, "  -- " .. section.category .. " " .. string.rep("-", 40 - #section.category))
    table.insert(lines, "")
    for _, item in ipairs(section.items) do
      local padding = string.rep(" ", 16 - #item.key)
      table.insert(lines, string.format("    %s%s%s", item.key, padding, item.desc))
    end
    table.insert(lines, "")
  end

  table.insert(lines, "  ------------------------------------------------------")
  table.insert(lines, "  Press q or Escape to close")
  table.insert(lines, "")

  local buf    = vim.api.nvim_create_buf(false, true)
  local width  = 60
  local height = math.min(#lines, math.floor(vim.o.lines * 0.85))
  local row    = math.floor((vim.o.lines - height) / 2)
  local col    = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")

  vim.api.nvim_open_win(buf, true, {
    relative  = "editor",
    width     = width,
    height    = height,
    row       = row,
    col       = col,
    style     = "minimal",
    border    = "rounded",
    title     = " Keybinds ",
    title_pos = "center",
  })

  vim.keymap.set("n", "q",     "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<CR>",  "<cmd>close<cr>", { buffer = buf, silent = true })
end

return M

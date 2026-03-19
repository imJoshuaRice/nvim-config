local map = vim.keymap.set

local function notes_path(subpath)
  return (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes\\" .. subpath
end

local nvim_scripts = (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\AppData\\Local\\nvim\\scripts\\"

-- Show a brief floating notification then auto-close
local function notify(msg, is_error)
  local lines = { "", "  " .. msg, "" }
  local width = #msg + 4
  local buf   = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local win = vim.api.nvim_open_win(buf, false, {
    relative  = "editor",
    width     = width,
    height    = 3,
    row       = vim.o.lines - 6,
    col       = math.floor((vim.o.columns - width) / 2),
    style     = "minimal",
    border    = "rounded",
    title     = is_error and " Error " or " Done ",
    title_pos = "center",
  })

  -- Auto-close after 3 seconds
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, 3000)
end

-- Run a PowerShell script silently and notify on completion
local function run_script(script, label)
  -- Run async using jobstart so Neovim doesn't block
  local stderr_lines = {}
  vim.fn.jobstart("powershell -NonInteractive -NoProfile -File " .. nvim_scripts .. script, {
    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if line ~= "" then table.insert(stderr_lines, line) end
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          notify(label .. " synced successfully")
        else
          notify(label .. " sync failed — check git status", true)
        end
      end)
    end,
  })
end

-- Note creation
map("n", "<leader>nf",  function() require("notes.templates").new_fleeting() end,         { desc = "New fleeting note" })
map("n", "<leader>nl",  function() require("notes.templates").new_literature() end,       { desc = "New literature note" })
map("n", "<leader>np",  function() require("notes.templates").new_permanent() end,        { desc = "New permanent note" })
map("n", "<leader>nP",  function() require("notes.templates").new_project() end,          { desc = "New project" })
map("n", "<leader>na",  function() require("notes.templates").new_area() end,             { desc = "New area / MoC" })
map("n", "<leader>npp", function() require("notes.templates").promote_to_permanent() end, { desc = "Promote fleeting to permanent" })
map("n", "<leader>nu", function() require("notes.templates").new_literature_from_url() end, { desc = "New literature note from URL" })

-- Navigation
map("n", "<leader>nt", function()
  vim.cmd("edit " .. vim.fn.fnameescape(notes_path("tasks.md")))
end, { desc = "Open tasks.md" })
map("n", "<leader>db", function() require("notes.dashboard").open() end, { desc = "Open dashboard" })
map("n", "<leader>B", function() require("notes.backlinks").show() end, { desc = "Show backlinks" })

-- Archive current note
map("n", "<leader>mv", function() require("notes.templates").archive_note() end, { desc = "Archive current note" })

-- Task management
map("n", "<leader>ta", function() require("notes.tasks").add_task() end,    { desc = "Add task" })
map("n", "<leader>tt", function() require("notes.tasks").toggle_task() end, { desc = "Toggle task" })
map("n", "<leader>to", function() require("notes.tasks").show_tasks() end,  { desc = "Show open tasks" })
map("n", "<leader>tc", function() require("notes.tasks").archive_completed() end, { desc = "Archive completed tasks" })

-- Git sync
map("n", "<leader>gs", function()
  run_script("sync-notes.ps1",  "Notes vault")
  run_script("sync-config.ps1", "Nvim config")
end, { desc = "Sync all to GitHub" })

map("n", "<leader>gp", function()
  run_script("publish-notes.ps1", "Public notes")
end, { desc = "Publish public notes" })

-- Search (defined in plugins/telescope.lua)
map("n", "<leader>st", function() require("notes.tagsearch").search() end, { desc = "Search by tag" })
map("n", "<leader>tg+", function() require("notes.tagger").add_tag() end,    { desc = "Add tag to note" })
map("n", "<leader>tg-", function() require("notes.tagger").remove_tag() end, { desc = "Remove tag from note" })
-- Frontmatter / type search
map("n", "<leader>sa",  function() require("notes.metasearch").search_all() end,        { desc = "Search all notes" })
map("n", "<leader>sff", function() require("notes.metasearch").search_fleeting() end,   { desc = "Search fleeting notes" })
map("n", "<leader>sl",  function() require("notes.metasearch").search_literature() end, { desc = "Search literature notes" })
map("n", "<leader>sP",  function() require("notes.metasearch").search_permanent() end,  { desc = "Search permanent notes" })
map("n", "<leader>spp", function() require("notes.metasearch").search_projects() end,   { desc = "Search projects" })
map("n", "<leader>sar", function() require("notes.metasearch").search_areas() end,      { desc = "Search areas" })
-- <leader>sf  search filenames
-- <leader>sg  grep all notes
-- <leader>sp  grep projects

-- General
map("n", "<leader>w",  "<cmd>w<cr>",                                              { desc = "Save file" })
map("n", "<leader>q",  "<cmd>q<cr>",                                              { desc = "Quit" })
map("n", "<leader>?",  function() require("notes.cheatsheet").open() end,         { desc = "Keybind cheatsheet" })
map("n", "<leader>e",  "<cmd>NvimTreeToggle<cr>",                                 { desc = "Toggle file explorer" })
map("n", "<leader>ef", "<cmd>NvimTreeFocus<cr>",                                  { desc = "Focus file explorer" })

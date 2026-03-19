local map = vim.keymap.set

local function notes_path(subpath)
  return (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes\\" .. subpath
end

local nvim_scripts = (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\AppData\\Local\\nvim\\scripts\\"

local function run_script(script)
  local result = vim.fn.system("powershell -File " .. nvim_scripts .. script)
  print(result)
end

-- Note creation
map("n", "<leader>nf", function() require("notes.templates").new_fleeting() end,   { desc = "New fleeting note" })
map("n", "<leader>nl", function() require("notes.templates").new_literature() end, { desc = "New literature note" })
map("n", "<leader>np", function() require("notes.templates").new_permanent() end,  { desc = "New permanent note" })
map("n", "<leader>nP", function() require("notes.templates").new_project() end,    { desc = "New project" })
map("n", "<leader>na", function() require("notes.templates").new_area() end,       { desc = "New area / MoC" })
map("n", "<leader>npp", function() require("notes.templates").promote_to_permanent() end, { desc = "Promote fleeting to permanent" })

-- Navigation
map("n", "<leader>nt", function()
  vim.cmd("edit " .. vim.fn.fnameescape(notes_path("tasks.md")))
end, { desc = "Open tasks.md" })
map("n", "<leader>db", function() require("notes.dashboard").open() end, { desc = "Open dashboard" })

-- Archive current note
map("n", "<leader>mv", function() require("notes.templates").archive_note() end, { desc = "Archive current note" })

-- Task management
map("n", "<leader>ta", function() require("notes.tasks").add_task() end,    { desc = "Add task" })
map("n", "<leader>tt", function() require("notes.tasks").toggle_task() end, { desc = "Toggle task" })
map("n", "<leader>to", function() require("notes.tasks").show_tasks() end,  { desc = "Show open tasks" })

-- Git sync
map("n", "<leader>gs", function()
  print("Syncing notes vault...")
  run_script("sync-notes.ps1")
  print("Syncing nvim config...")
  run_script("sync-config.ps1")
  print("Sync complete.")
end, { desc = "Sync all to GitHub" })

map("n", "<leader>gp", function()
  run_script("publish-notes.ps1")
end, { desc = "Publish public notes" })

-- Search (defined in plugins/telescope.lua)
-- <leader>sf  search filenames
-- <leader>sg  grep all notes
-- <leader>sp  grep projects

-- General
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })

-- File explorer
map("n", "<leader>e",  "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file explorer" })
map("n", "<leader>ef", "<cmd>NvimTreeFocus<cr>",  { desc = "Focus file explorer" })

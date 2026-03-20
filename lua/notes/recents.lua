local M = {}

local function notes_root()
  return (os.getenv("USERPROFILE") or vim.fn.expand("~")) .. "\\notes"
end

local function recents_path()
  return notes_root() .. "\\.recents.json"
end

local MAX_RECENTS = 5

local function read_recents()
  local f = io.open(recents_path(), "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok or type(data) ~= "table" then return {} end
  return data
end

local function write_recents(recents)
  local f = io.open(recents_path(), "w")
  if not f then return end
  f:write(vim.fn.json_encode(recents))
  f:close()
end

function M.record(filepath)
  local root = notes_root()
  if not filepath:find(root, 1, true) then return end
  if filepath:match("tasks%.md$") then return end

  local recents = read_recents()

  -- Remove if already present
  for i, v in ipairs(recents) do
    if v == filepath then table.remove(recents, i); break end
  end

  -- Add to front
  table.insert(recents, 1, filepath)

  -- Trim to max
  while #recents > MAX_RECENTS do
    table.remove(recents)
  end

  write_recents(recents)
end

function M.get()
  return read_recents()
end

return M

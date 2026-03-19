local M = {}

-- Add a tag to the current note's frontmatter
function M.add_tag()
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then print("No file open"); return end

  local tag = vim.fn.input("Add tag: ")
  if tag == "" then return end
  tag = tag:gsub("%s+", "-"):lower()

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local in_frontmatter = false
  local checked_first  = false
  local tags_line      = nil

  for i, line in ipairs(lines) do
    if not checked_first then
      checked_first = true
      if line:match("^---") then in_frontmatter = true end
    elseif in_frontmatter then
      if line:match("^---") then break end
      if line:match("^tags:") then
        tags_line = i
        break
      end
    end
  end

  if not tags_line then
    print("No tags: field found in frontmatter")
    return
  end

  local current = lines[tags_line]

  -- Handle tags: [] (empty)
  if current:match("^tags:%s*%[%s*%]") then
    lines[tags_line] = "tags: [" .. tag .. "]"

  -- Handle tags: [existing, tags]
  elseif current:match("^tags:%s*%[.+%]") then
    lines[tags_line] = current:gsub("%]$", ", " .. tag .. "]")

  -- Handle tags: (no brackets, treat as empty)
  else
    lines[tags_line] = "tags: [" .. tag .. "]"
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.cmd("silent! write")
  print("Tag added: " .. tag)
end

-- Remove a tag from the current note's frontmatter
function M.remove_tag()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local in_frontmatter = false
  local checked_first  = false
  local tags_line      = nil
  local current_tags   = {}

  for i, line in ipairs(lines) do
    if not checked_first then
      checked_first = true
      if line:match("^---") then in_frontmatter = true end
    elseif in_frontmatter then
      if line:match("^---") then break end
      if line:match("^tags:") then
        tags_line = i
        local inline = line:match("^tags:%s*%[(.-)%]")
        if inline then
          for t in inline:gmatch("[^,%s]+") do
            table.insert(current_tags, t)
          end
        end
        break
      end
    end
  end

  if not tags_line or #current_tags == 0 then
    print("No tags to remove")
    return
  end

  -- Show current tags and prompt
  local tag_display = table.concat(current_tags, ", ")
  local tag = vim.fn.input("Remove tag (" .. tag_display .. "): ")
  if tag == "" then return end
  tag = tag:gsub("%s+", "-"):lower()

  -- Filter out the tag
  local new_tags = {}
  for _, t in ipairs(current_tags) do
    if t ~= tag then table.insert(new_tags, t) end
  end

  if #new_tags == #current_tags then
    print("Tag not found: " .. tag)
    return
  end

  lines[tags_line] = "tags: [" .. table.concat(new_tags, ", ") .. "]"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.cmd("silent! write")
  print("Tag removed: " .. tag)
end

return M

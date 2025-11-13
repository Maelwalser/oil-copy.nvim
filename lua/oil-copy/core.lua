local M = {}

---
--- Copies the recursive contents of a directory OR
--- the content of a single file to the system clipboard.
---
function M.copy_entry_contents()
  local oil = require("oil")
  local entry = oil.get_cursor_entry()

  if not entry then
    vim.notify("Not on a valid entry", vim.log.levels.WARN)
    return
  end

  if not entry.name or entry.name == ".." then
    vim.notify("Cannot copy parent directory reference", vim.log.levels.WARN)
    return
  end

  -- Get the current Oil directory and construct the full path
  local dir = oil.get_current_dir()
  if not dir then
    vim.notify("Could not determine current directory", vim.log.levels.ERROR)
    return
  end

  -- Construct full path: remove trailing slash if present, then add entry name
  local full_path = dir:gsub("/$", "") .. "/" .. entry.name

  -- Handle Directories
  if entry.type == "directory" then
    local all_content = ""
    local file_count = 0

    -- Define recursive traverse function
    local function traverse(path)
      local ok, items = pcall(vim.fn.readdir, path)
      if not ok then
        vim.notify("Could not read directory: " .. tostring(path), vim.log.levels.ERROR)
        return
      end

      for _, item in ipairs(items) do
        if item ~= "." and item ~= ".." then
          local item_path = path .. "/" .. item
          if vim.fn.isdirectory(item_path) == 1 then
            traverse(item_path) -- Recurse
          else
            if vim.fn.filereadable(item_path) == 1 then
              local read_ok, content_lines = pcall(vim.fn.readfile, item_path)
              if read_ok then
                all_content = all_content
                    .. "-- "
                    .. item_path
                    .. "\n\n"
                    .. table.concat(content_lines, "\n")
                    .. "\n\n"
                file_count = file_count + 1
              else
                vim.notify("Could not read file: " .. tostring(item_path), vim.log.levels.WARN)
              end
            end
          end
        end
      end
    end

    -- Start the traversal
    traverse(full_path)

    if all_content ~= "" then
      vim.fn.setreg("+", all_content) -- Copy to system clipboard
      vim.notify("Copied content of " .. file_count .. " files to clipboard", vim.log.levels.INFO)
    else
      vim.notify("No readable files found in directory", vim.log.levels.WARN)
    end

    -- Handle Files
  elseif entry.type == "file" then
    if vim.fn.filereadable(full_path) == 0 then
      vim.notify("File is not readable: " .. full_path, vim.log.levels.WARN)
      return
    end

    -- Safely read the file
    local read_ok, content_lines = pcall(vim.fn.readfile, full_path)

    if not read_ok then
      vim.notify("Could not read file (e.g., binary): " .. full_path, vim.log.levels.ERROR)
      return
    end

    local file_content = table.concat(content_lines, "\n")
    vim.fn.setreg("+", file_content)
    vim.notify("Copied content of " .. entry.name, vim.log.levels.INFO)

    -- Handle Other Types
  else
    vim.notify("Cannot copy contents of type: " .. entry.type, vim.log.levels.WARN)
  end
end

---
--- Copies the contents of multiple selected entries (visual mode)
---
function M.copy_visual_selection()
  local oil = require("oil")
  
  -- Get visual selection range
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  
  -- Get the current Oil directory
  local dir = oil.get_current_dir()
  if not dir then
    vim.notify("Could not determine current directory", vim.log.levels.ERROR)
    return
  end
  
  -- Save current cursor position
  local original_pos = vim.api.nvim_win_get_cursor(0)
  
  -- First, collect all entries to process
  local entries_to_process = {}
  local buf = vim.api.nvim_get_current_buf()
  local line_count = vim.api.nvim_buf_line_count(buf)
  
  for line_num = start_line, end_line do
    if line_num <= line_count then
      -- Safely set cursor position
      pcall(vim.api.nvim_win_set_cursor, 0, {line_num, 0})
      local entry = oil.get_cursor_entry()
      
      if entry and entry.name and entry.name ~= ".." then
        local full_path = dir:gsub("/$", "") .. "/" .. entry.name
        table.insert(entries_to_process, {
          path = full_path,
          type = entry.type,
          name = entry.name
        })
      end
    end
  end
  
  -- Restore cursor position
  pcall(vim.api.nvim_win_set_cursor, 0, original_pos)
  
  if #entries_to_process == 0 then
    vim.notify("No valid entries selected", vim.log.levels.WARN)
    return
  end
  
  local all_content = ""
  local file_count = 0
  local processed_paths = {}
  
  -- Helper function to read a single file and add to content
  local function add_file_content(file_path, include_comment)
    if vim.fn.filereadable(file_path) == 1 then
      local read_ok, content_lines = pcall(vim.fn.readfile, file_path)
      if read_ok then
        if include_comment then
          all_content = all_content .. "-- " .. file_path .. "\n\n"
        end
        all_content = all_content .. table.concat(content_lines, "\n") .. "\n\n"
        file_count = file_count + 1
        return true
      else
        vim.notify("Could not read file: " .. tostring(file_path), vim.log.levels.WARN)
      end
    end
    return false
  end
  
  -- Recursive function to traverse directories
  local function traverse_directory(path)
    local ok, items = pcall(vim.fn.readdir, path)
    if not ok then
      vim.notify("Could not read directory: " .. tostring(path), vim.log.levels.ERROR)
      return
    end
    
    for _, item in ipairs(items) do
      if item ~= "." and item ~= ".." then
        local item_path = path .. "/" .. item
        if vim.fn.isdirectory(item_path) == 1 then
          traverse_directory(item_path)
        else
          add_file_content(item_path, true)
        end
      end
    end
  end
  
  -- Now process all collected entries
  for _, entry in ipairs(entries_to_process) do
    if not processed_paths[entry.path] then
      processed_paths[entry.path] = true
      
      if entry.type == "directory" then
        traverse_directory(entry.path)
      elseif entry.type == "file" then
        add_file_content(entry.path, true) -- Always include comment for multiple files
      end
    end
  end
  
  if all_content ~= "" then
    vim.fn.setreg("+", all_content)
    vim.notify("Copied content of " .. file_count .. " files to clipboard", vim.log.levels.INFO)
  else
    vim.notify("No readable files found in selection", vim.log.levels.WARN)
  end
end

return M

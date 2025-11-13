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

  -- Handle Directories
  if entry.type == "directory" then
    local dir_path = entry.path
    local all_content = ""
    local file_count = 0

    -- Define recursive traverse function
    local function traverse(path)
      local ok, items = pcall(vim.fn.readdir, path)
      if not ok then
        vim.notify("Could not read directory: " .. path, vim.log.levels.ERROR)
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
                vim.notify("Could not read file: " .. item_path, vim.log.levels.WARN)
              end
            end
          end
        end
      end
    end

    -- Start the traversal
    traverse(dir_path)

    if all_content ~= "" then
      vim.fn.setreg("+", all_content) -- Copy to system clipboard
      vim.notify("Copied content of " .. file_count .. " files to clipboard", vim.log.levels.INFO)
    else
      vim.notify("No readable files found in directory", vim.log.levels.WARN)
    end

  -- Handle Files
  elseif entry.type == "file" then
    local file_path = entry.path
    if vim.fn.filereadable(file_path) == 0 then
      vim.notify("File is not readable: " .. file_path, vim.log.levels.WARN)
      return
    end

    -- Safely read the file
    local read_ok, content_lines = pcall(vim.fn.readfile, file_path)

    if not read_ok then
      vim.notify("Could not read file (e.g., binary): " .. file_path, vim.log.levels.ERROR)
      return
    end

    local file_content = table.concat(content_lines, "\n")
    vim.fn.setreg("+", file_content)
    local filename = vim.fn.fnamemodify(file_path, ":t")
    vim.notify("Copied content of " .. filename, vim.log.levels.INFO)

  -- Handle Other Types
  else
    vim.notify("Cannot copy contents of type: " .. entry.type, vim.log.levels.WARN)
  end
end

return M

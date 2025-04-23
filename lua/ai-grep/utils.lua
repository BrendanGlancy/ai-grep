local M = {}

-- Get the root directory of the current project
function M.get_project_root()
  local current_file = vim.fn.expand('%:p')
  local current_dir = vim.fn.fnamemodify(current_file, ':h')
  
  -- Try to find git root
  local git_root = vim.fn.systemlist('cd ' .. vim.fn.escape(current_dir, ' ') .. ' && git rev-parse --show-toplevel')[1]
  if git_root and vim.v.shell_error == 0 then
    return git_root
  end
  
  -- Fallback to current directory
  return current_dir
end

-- Get relevant files to build context
function M.get_relevant_files(max_files)
  max_files = max_files or 50
  local root = M.get_project_root()
  
  -- Use ripgrep to find text files, excluding common binary and large files
  local cmd = string.format(
    'cd %s && rg --files --max-count=%d --type-not binary --glob "!{*.lock,*.min.*,node_modules/**,vendor/**,dist/**}"',
    vim.fn.escape(root, ' '),
    max_files
  )
  
  local files = vim.fn.systemlist(cmd)
  return files
end

-- Get a summary of the project structure
function M.get_project_summary()
  local root = M.get_project_root()
  local cmd = string.format(
    'cd %s && find . -type f -name "*.json" -not -path "*/node_modules/*" -not -path "*/dist/*" | grep -l "package\\.json"',
    vim.fn.escape(root, ' ')
  )
  
  local package_jsons = vim.fn.systemlist(cmd)
  local summary = {}
  
  -- Try to extract dependencies from package.json
  for _, file in ipairs(package_jsons) do
    local file_path
    -- Handle paths correctly depending on format
    if file:sub(1, 2) == "./" then
      file_path = root .. '/' .. file:sub(3)
    else
      file_path = root .. '/' .. file
    end
    
    -- Check if file exists before trying to read it
    local ok, content = pcall(vim.fn.readfile, file_path)
    if not ok then
      vim.notify("Could not read file: " .. file_path, vim.log.levels.WARN)
      goto continue
    end
    
    local ok, package_info = pcall(vim.fn.json_decode, table.concat(content, '\n'))
    if not ok or not package_info then
      vim.notify("Could not parse JSON from: " .. file_path, vim.log.levels.WARN)
      goto continue
    end
    
    if package_info.dependencies or package_info.devDependencies then
      summary.dependencies = package_info.dependencies or {}
      summary.devDependencies = package_info.devDependencies or {}
      break
    end
    
    ::continue::
  end
  
  return summary
end

-- Build comprehensive project context for Claude
function M.get_project_context()
  local root = M.get_project_root()
  local files = {}
  
  -- Add error handling to file retrieval
  local ok, result = pcall(M.get_relevant_files, 20) -- Limit to 20 most relevant files
  if ok and result then
    files = result
  else
    vim.notify("Failed to get relevant files", vim.log.levels.WARN)
  end
  
  -- Add error handling to project summary
  local summary = {}
  ok, result = pcall(M.get_project_summary)
  if ok and result then
    summary = result
  else
    vim.notify("Failed to get project summary", vim.log.levels.WARN)
  end
  
  local context = {
    project_root = root,
    summary = summary,
    file_samples = {}
  }
  
  -- Get samples from key files
  for _, file in ipairs(files) do
    local full_path = root .. '/' .. file
    
    -- Add error handling when reading file content
    local ok, content = pcall(vim.fn.readfile, full_path)
    if not ok or not content then
      vim.notify("Could not read file: " .. full_path, vim.log.levels.DEBUG)
      goto continue
    end
    
    if #content > 0 then
      -- Limit file content to prevent token overuse
      local sample = {}
      for i = 1, math.min(50, #content) do
        table.insert(sample, content[i])
      end
      context.file_samples[file] = table.concat(sample, '\n')
    end
    
    ::continue::
  end
  
  return context
end

-- Create a temporary file with content
function M.create_temp_file(content)
  local temp_file = vim.fn.tempname()
  vim.fn.writefile(vim.split(content, '\n'), temp_file)
  return temp_file
end

-- Display results in a floating window
function M.display_results(results)
  local bufnr = vim.api.nvim_create_buf(false, true)
  
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
  
  local lines = {}
  for _, result in ipairs(results) do
    table.insert(lines, result.file .. ':' .. result.line .. ': ' .. result.text)
    table.insert(lines, '')
  end
  
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
  
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  }
  
  local win = vim.api.nvim_open_win(bufnr, true, opts)
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  
  -- Add keybindings to navigate and select results
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', ':q<CR>', {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<CR>', [[<cmd>lua require('ai-grep.utils').open_result()<CR>]], {noremap = true, silent = true})
  
  return {bufnr = bufnr, win = win}
end

-- Open the selected result
function M.open_result()
  local line = vim.fn.getline('.')
  local parts = vim.split(line, ':')
  
  if #parts >= 2 then
    local file = parts[1]
    local line_num = tonumber(parts[2])
    
    vim.cmd('q') -- Close the results window
    vim.cmd('edit ' .. file)
    if line_num then
      vim.api.nvim_win_set_cursor(0, {line_num, 0})
      vim.cmd('normal! zz')
    end
  end
end

return M
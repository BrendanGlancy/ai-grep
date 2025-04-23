local M = {}
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')
local ai_grep = require('ai-grep')
local utils = require('ai-grep.utils')

function M.setup(opts)
  M.opts = opts
  
  if pcall(require, 'telescope') then
    -- Register the telescope extension
    require('telescope').register_extension({
      exports = {
        ['ai-grep'] = function(opts)
          M.ai_grep(opts)
        end
      }
    })
  else
    vim.notify('Telescope not found. ai-grep.telescope integration disabled.', vim.log.levels.WARN)
  end
end

function M.ai_grep(opts)
  opts = opts or {}
  opts = vim.tbl_deep_extend('force', M.opts or {}, opts)
  
  local query = opts.query or vim.fn.input('AI Grep > ')
  if not query or query == '' then
    return
  end
  
  -- Show a notification that we're querying Claude
  vim.notify('Querying Claude AI...', vim.log.levels.INFO)
  
  -- Perform the search with Claude
  local project_context = utils.get_project_context()
  local results = ai_grep.grep(query, opts)
  
  if #results == 0 then
    vim.notify('No results found', vim.log.levels.INFO)
    return
  end
  
  -- Format results for telescope
  local items = {}
  for _, result in ipairs(results) do
    table.insert(items, {
      filename = result.file,
      lnum = result.line,
      text = result.text,
      context = result.context,
      relevance = result.relevance,
    })
  end
  
  -- Create and run the picker
  pickers.new(opts, {
    prompt_title = 'AI Grep: ' .. query,
    finder = finders.new_table({
      results = items,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.filename .. ':' .. entry.lnum .. ': ' .. entry.text .. ' [' .. entry.relevance .. '%]',
          ordinal = entry.filename .. ':' .. entry.lnum .. ':' .. entry.text,
          filename = entry.filename,
          lnum = entry.lnum,
          col = 0,
          text = entry.text,
          context = entry.context,
        }
      end
    }),
    sorter = conf.generic_sorter(opts),
    previewer = previewers.new_buffer_previewer({
      title = 'Context',
      define_preview = function(self, entry, status)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(entry.context, '\n'))
        vim.api.nvim_buf_set_option(self.state.bufnr, 'filetype', 'lua') -- Try to set a reasonable filetype
      end
    }),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        
        if selection then
          vim.cmd('edit ' .. selection.filename)
          vim.api.nvim_win_set_cursor(0, {selection.lnum, 0})
          vim.cmd('normal! zz')
        end
      end)
      return true
    end,
  }):find()
end

return M
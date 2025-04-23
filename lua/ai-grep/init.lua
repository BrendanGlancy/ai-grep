local M = {}
local utils = require('ai-grep.utils')
local claude = require('ai-grep.claude')

function M.setup(opts)
  opts = opts or {}
  M.opts = vim.tbl_deep_extend('force', {
    claude_api_key = vim.env.CLAUDE_API_KEY,
    model = "claude-3-opus-20240229",
    telescope = {
      enabled = true,
    },
  }, opts)
  
  if M.opts.telescope.enabled then
    require('ai-grep.telescope').setup(M.opts)
  end
end

function M.grep(query, opts)
  opts = opts or {}
  opts = vim.tbl_deep_extend('force', M.opts or {}, opts)
  
  local project_context = utils.get_project_context()
  local results = claude.search(project_context, query, opts)
  
  return results
end

return M
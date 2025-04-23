if vim.g.loaded_ai_grep then
  return
end
vim.g.loaded_ai_grep = true

vim.api.nvim_create_user_command('AIGrep', function(opts)
  require('ai-grep.telescope').ai_grep({query = opts.args})
end, {nargs = '?', desc = 'Smart code search using Claude AI'})

vim.api.nvim_create_user_command('AIGrepExplain', function(opts)
  -- TODO: Implement explanation functionality
  print('Not implemented yet')
end, {nargs = '?', desc = 'Ask Claude AI to explain code'})
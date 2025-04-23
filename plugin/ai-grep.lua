if vim.g.loaded_ai_grep then
    return
end
vim.g.loaded_ai_grep = true

vim.api.nvim_create_user_command('AIGrep', function(opts)
    require('ai-grep.ui').ai_grep({ query = opts.args })
end, { nargs = '?', desc = 'Smart code search using Claude AI' })

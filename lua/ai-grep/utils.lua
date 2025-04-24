local M = {}

function M.get_project_root()
    local current_file = vim.fn.expand('%:p')
    local current_dir = vim.fn.fnamemodify(current_file, ':h')

    local git_root = vim.fn.systemlist('cd ' .. vim.fn.shellescape(current_dir) .. ' && git rev-parse --show-toplevel')
        [1]
        [1]
    if git_root and vim.v.shell_error == 0 then
        return git_root
    end

    return current_dir
end

function M.get_relevant_files()
    local root = M.get_project_root()
    local cmd = string.format(
        'cd %s && rg --files --glob "!{*.lock,*.min.*,node_modules/**,vendor/**,dist/**}"',
        vim.fn.escape(root, ' ')
    )

    return vim.fn.systemlist(cmd)
end

function M.display_results(results)
    local bufnr  = vim.api.nvim_create_buf(false, true)
    local width  = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row    = math.floor((vim.o.lines - height) / 2)
    local col    = math.floor((vim.o.columns - width) / 2)

    local lines  = {}
    for _, result in ipairs(results) do
        table.insert(lines, result.file .. ':' .. result.line .. ':' .. result.text)
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
        border = 'rounded'
    }

    local win = vim.api.nvim_open_win(bufnr, true, opts)
    vim.api.nvim_win_set_option(win, 'cursorline', true)

    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', ':q<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<CR>', [[<cmd>lua require('ai-grep.utils').open_result()<CR>]],
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Esc>', ':q<CR>', { noremap = true, silent = true })

    return { bufnr = bufnr, win = win }
end

function M.open_result()
    local line = vim.fn.getline('.')
    local file, lineno, text = line:match("^(.-):(%d+):(.+)$")

    if file and lineno then
        vim.cmd('q')
        vim.cmd('edit ' .. file)
        vim.api.nvim_win_set_cursor(0, { tonumber(lineno), 0 })
        vim.cmd('normal! zz')
    end
end

function M.rip_grep(query)
    local root = M.get_project_root()
    local cmd = string.format(
        'cd %s && rg --vimgrep --no-heading --with-filename --line-number --color never %s',
        vim.fn.shellescape(root),
        vim.fn.shellescape(query)
    )

    local lines = vim.fn.systemlist(cmd)
    if vim.v.shell_error ~= 0 or #lines == 0 then
        return {}
    end

    local results = {}
    for _, line in ipairs(lines) do
        local file, lineno, col, text = line:match("^(.-):(%d+):(%d+):(.+)$")
        if file and lineno and text then
            table.insert(results, {
                file = file,
                line = tonumber(lineno),
                text = vim.trim(text)
            })
        end
    end

    return results
end

return M

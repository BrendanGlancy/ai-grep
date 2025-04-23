local M = {}

function M.open_prompt(callback)
    local buf = vim.api.nvim_create_buf(false, true)
    local width = math.floor(vim.o.columns * 0.5)
    local height = 1
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local opts = {
        style = "minimal",
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        border = "rounded",
    }

    local win = vim.api.nvim_open_win(buf, true, opts)

    vim.api.nvim_buf_set_option(buf, 'buflisted', false)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'prompt')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.fn.prompt_setprompt(buf, 'AI-Grep > ')
    vim.cmd('startinsert')

    vim.fn.prompt_setcallback(buf, function(input)
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, { force = true })
        callback(input)
    end)
end

return M

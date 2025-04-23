local M = {}

function M.setup(opts)
  opts = opts or {}
  opts.keymaps = opts.keymaps or {}

  local key = opts.keymaps.aigrep or "<leader>ag"

  vim.keymap.set("n", key, function()
    require("ai-grep.ui").start()
  end, { desc = "AI-Grep (ripgrep search)" })
end

return M

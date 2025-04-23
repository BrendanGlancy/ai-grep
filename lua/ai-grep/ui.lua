local window = require('ai-grep.window')
local utils = require('ai-grep.utils')

local M = {}

function M.start()
    window.open_prompt(function(query)
        if not query or query == "" then
            vim.notify("No query provided", vim.log.levels.WARN)
            return
        end

        local results = utils.rip_grep(query)
        if #results == 0 then
            vim.notify("No matches found for: " .. query)
            return
        end

        utils.display_results(results)
    end)
end

return M

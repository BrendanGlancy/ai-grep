local M = {}
local utils = require('ai-grep.utils')
local curl = require('plenary.curl')

-- Use built-in vim functions for JSON instead of vim.json module
local json = {
  encode = vim.fn.json_encode,
  decode = vim.fn.json_decode
}

-- Send request to Claude API
function M.request(prompt, opts)
  opts = opts or {}
  local api_key = opts.claude_api_key or vim.env.CLAUDE_API_KEY
  
  if not api_key then
    vim.notify('Claude API key not found. Set it in setup() or CLAUDE_API_KEY env var', vim.log.levels.ERROR)
    return nil
  end
  
  local model = opts.model or "claude-3-opus-20240229"
  
  local response = curl.post({
    url = "https://api.anthropic.com/v1/messages",
    headers = {
      ["Content-Type"] = "application/json",
      ["anthropic-version"] = "2023-06-01",
      ["x-api-key"] = api_key,
    },
    body = json.encode({
      model = model,
      max_tokens = 4000,
      messages = {
        {
          role = "user",
          content = prompt
        }
      }
    }),
  })
  
  if response.status ~= 200 then
    vim.notify('Claude API request failed: ' .. (response.body or 'Unknown error'), vim.log.levels.ERROR)
    return nil
  end
  
  local result = json.decode(response.body)
  return result
end

-- Build a prompt for smart search
function M.build_search_prompt(context, query)
  local prompt = [[I need you to act as a smart code search tool. I'm going to provide you with:
1. A description of my project
2. Some sample files from my project
3. A search query

Your task is to find the most relevant code matches for my query and return them in a specific JSON format.

Here's information about my project:
]]
  
  -- Add project summary
  prompt = prompt .. "\nProject root: " .. context.project_root
  
  if context.summary and context.summary.dependencies then
    prompt = prompt .. "\n\nDependencies:\n"
    for dep, ver in pairs(context.summary.dependencies) do
      prompt = prompt .. "- " .. dep .. ": " .. ver .. "\n"
    end
  end
  
  -- Add file samples
  prompt = prompt .. "\n\nHere are some sample files from the project:\n"
  
  for file, content in pairs(context.file_samples) do
    prompt = prompt .. "\n--- File: " .. file .. " ---\n" .. content .. "\n---\n"
  end
  
  -- Add the search query and output format instructions
  prompt = prompt .. [[  

Search query: ]] .. query .. [[

Please find matches in the provided files that best answer this query. Consider:  
1. Exact text matches
2. Semantic matches (code that relates to the query conceptually) 
3. Function/class/variable names that match
4. Comments that describe relevant functionality

Output the results as a JSON array with this format:
[
  {
    "file": "relative/path/to/file.ext",
    "line": line_number,
    "text": "the matching line of code",
    "relevance": 0-100 score indicating match quality,
    "context": "2-3 lines of context around the match"    
  },
  ...
]

Limit results to the 5-10 most relevant matches, with highest relevance first. Output ONLY the JSON, no other text.
]]

  return prompt
end

-- Parse search results from Claude response
function M.parse_results(response)
  if not response or not response.content or #response.content == 0 then
    return {}
  end
  
  local content = response.content[1].text
  
  -- Try to extract JSON
  local json_str = content:match('%[%s*{.-}%s*%]')
  if not json_str then
    vim.notify('Failed to extract JSON from Claude response', vim.log.levels.ERROR)
    return {}
  end
  
  local ok, results = pcall(json.decode, json_str)
  if not ok or not results then
    vim.notify('Failed to parse JSON from Claude response', vim.log.levels.ERROR)
    return {}
  end
  
  return results
end

-- Perform a smart search using Claude
function M.search(context, query, opts)
  local prompt = M.build_search_prompt(context, query)
  local response = M.request(prompt, opts)
  local results = M.parse_results(response)
  
  return results
end

return M
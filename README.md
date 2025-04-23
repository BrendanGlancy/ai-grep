# AI-Grep: Claude-powered Smart Code Search for Neovim

AI-Grep is a Neovim plugin that uses Claude AI to provide intelligent, context-aware code search capabilities beyond traditional regex-based tools like ripgrep.

## Features

- Semantic code search using Claude AI's understanding of your codebase
- Finds code based on concepts and meaning, not just text patterns
- Telescope integration for familiar navigation
- Displays relevance scores to help identify the best matches

## Requirements

- Neovim 0.5.0+
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (for telescope integration)
- Claude API key

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'yourusername/ai-grep',
  requires = {
    {'nvim-lua/plenary.nvim'},
    {'nvim-telescope/telescope.nvim'}
  }
}
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'yourusername/ai-grep',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require('ai-grep').setup({
      claude_api_key = "your_api_key", -- Or set CLAUDE_API_KEY env var
    })
  end
}
```

## Configuration

```lua
require('ai-grep').setup({
  claude_api_key = "your_api_key", -- Or set CLAUDE_API_KEY env var
  model = "claude-3-opus-20240229", -- Claude model to use
  telescope = {
    enabled = true, -- Set to false to disable telescope integration
  },
})
```

## Usage

### Commands

- `:AIGrep [query]` - Search your codebase using Claude AI with an optional initial query
- `:AIGrepExplain` - (Coming soon) Ask Claude to explain a piece of code

### Telescope Extension

```lua
:Telescope ai-grep
```

## How It Works

AI-Grep builds context about your project by examining key files and dependencies, then sends this context along with your search query to the Claude API. Claude analyzes the code semantically and returns the most relevant matches.

The plugin formats these results and presents them through Telescope's familiar interface, making it easy to navigate to the matches in your codebase.

## License

MIT
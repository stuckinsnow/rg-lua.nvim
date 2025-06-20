# rg-lua

A Neovim plugin for searching files with ripgrep and displaying results in markdown format.

## Features

- 🔍 Interactive search with ripgrep
- 🔀 AND/OR search modes for multiple terms
- 📋 Unique file filtering options
- 📝 Clean markdown formatted results
- 📁 File picker integration with fzf-lua
- 💾 Save results to markdown files
- ⚡ Fast async search with loading spinner

## Requirements

- Neovim 0.9+
- ripgrep (`rg` command)
- fzf-lua

## Installation

### Using lazy.nvim

```lua
{
  "stuckinsnow/rg-lua",
  dependencies = {
    "ibhagwan/fzf-lua",
  },
  config = function()
    require("rg-lua").setup()
  end,
}
```

### Using packer.nvim

```lua
use {
  "stuckinsnow/rg-lua",
  requires = {
    "ibhagwan/fzf-lua",
  },
  config = function()
    require("rg-lua").setup()
  end,
}
```

## Usage

### Commands

- `:RgSearch` - Start interactive search

### Lua API

```lua
-- Start search
require("rg-lua").search()
```

### Search Flow

1. Enter search terms (space-separated)
2. Choose search mode:
   - **Single term**: "All Results" vs "Unique Files Only"
   - **Multiple terms**: "OR Search", "AND Search", "Unique OR", "Unique AND"
3. View results in markdown format

### Search Modes Explained

- **OR Search**: Find lines containing _any_ of the search terms
- **AND Search**: Find lines containing _all_ search terms on the same line
- **Unique**: Show only the first match per file (useful for file discovery)

### Key Bindings in Results Buffer

| Key    | Action                                         |
| ------ | ---------------------------------------------- |
| `q`    | Close results window                           |
| `<CR>` | Open fzf file picker to select and edit a file |
| `s`    | Save results to markdown file                  |

## Example

Search for "function" and "local":

```
Search terms: function local
Search mode: AND Search
```

Results will show lines containing both "function" AND "local", formatted as:

```markdown
# Search Results

**Search Terms:** function local
**Search Mode:** AND Search  
**Date:** 2024-01-15 10:30:45

## 📁 Found 5 files:

- `init.lua`
- `search.lua`
- `utils.lua`

## Search Results
```

init.lua:15:local function setup_commands()
search.lua:23: local function validate_terms(terms)
utils.lua:8:local function create_buffer()

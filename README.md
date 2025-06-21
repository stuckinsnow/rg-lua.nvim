# rg-lua

A Neovim plugin for searching files with ripgrep and displaying results in a clean, grouped format.

## Features

- 🔍 Interactive search with ripgrep
- 🔀 AND/OR search modes for multiple terms
- 📋 Unique file filtering options
- 📝 Clean grouped results by file with syntax highlighting
- 📁 File picker integration with fzf-lua
- 💾 Save results to markdown files
- ⚡ Fast async search with animated loading spinner
- 🎨 Search term highlighting in results

## Requirements

- Neovim 0.9+
- ripgrep (`rg` command)
- fzf-lua (optional, for file picker functionality)

## Installation

### Using lazy.nvim

```lua
{
  "stuckinsnow/rg-lua",
  dependencies = {
    "ibhagwan/fzf-lua", -- optional
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
3. View results grouped by file with syntax highlighting

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

## Syntax Highlighting

The results buffer uses custom syntax highlighting to improve readability:

- **Headers** - Search metadata (terms, mode, date, file count)
- **File paths** - Files containing matches
- **Line numbers** - `15:` format for easy navigation
- **Search terms** - Highlighted throughout results for quick identification

### Highlight Groups

You can customize the colors by setting these highlight groups in your colorscheme or init.lua:

```lua
-- Headers (Search Terms, Mode, Date, Found X files)
"RgResultsHeader"
"RgResultsFile"
"RgResultsFileList"
"RgResultsLineNr"
"RgResultsMatch"
"RgResultsContent"
```

## Tips & Tricks

- Use **Unique** modes to quickly discover which files contain your search terms
- **AND Search** is perfect for finding complex patterns (e.g., "function" AND "async")
- **OR Search** casts a wider net when you're not sure of exact terminology
- The file picker (`<CR>`) includes preview with `bat` if available
- Save results (`s`) for documentation or sharing with team members

## File Output Format

When saving results, the plugin preserves the clean grouped format:

- Plain text file with `.txt` extension
- Maintains all search metadata and grouping
- Perfect for sharing or archiving search results

## Configuration

To change the width of the results buffer, you can set this in your Neovim configuration:

```lua
require("rg-lua").setup({
  use_main_buffer = true,
  width_percent = 0.3
})
```

## Example

Search for "function" and "local":

```
Search terms: function local
Search mode: AND Search
```

Results will show lines containing both "function" AND "local", grouped by file:

```
Search Terms: function local
Search Mode: AND Search
Date: 2024-01-15 10:30:45

Found 3 files:
./init.lua
./search.lua
./utils.lua

./init.lua
15:local function setup_commands()
42:  local function validate_input()

./search.lua
23:local function validate_terms(terms)
56:local function build_pattern()

./utils.lua
8:local function create_buffer()
```

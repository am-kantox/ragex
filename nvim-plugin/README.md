# ragex.nvim

Full-featured NeoVim/LunarVim plugin for [Ragex](https://github.com/Oeditus/ragex) - Hybrid RAG system for multi-language codebase analysis.

## Features

- Semantic code search with natural language queries
- Hybrid search combining symbolic and semantic approaches
- Safe project-wide refactoring (rename functions/modules with AST awareness)
- Advanced refactoring operations (extract function, inline, change signature, etc.)
- Call graph analysis and visualization
- Code quality analysis (duplication, dead code, complexity)
- Impact analysis and risk assessment
- Advanced graph algorithms (centrality metrics, community detection)
- Real-time progress notifications
- Beautiful Telescope UI integration
- Auto-analysis on file save
- Status line integration

## Requirements

- NeoVim 0.9+ or LunarVim
- [Ragex](https://github.com/Oeditus/ragex) MCP server running
- Elixir 1.19+ (for Ragex server)
- Telescope.nvim (for UI)
- plenary.nvim (for async operations)
- Optional: socat or luasocket for Unix socket communication

## Installation

### Using lazy.nvim (NeoVim)

```lua
{
  "Oeditus/ragex.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("ragex").setup({
      ragex_path = vim.fn.expand("~/path/to/ragex"),
      auto_analyze = false,  -- Enable auto-analysis on save
      debug = false,         -- Enable debug logging
    })
  end,
}
```

### Using packer.nvim

```lua
use {
  "Oeditus/ragex.nvim",
  requires = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("ragex").setup()
  end,
}
```

### LunarVim

Add to your `~/.config/lvim/config.lua`:

```lua
lvim.plugins = {
  {
    "Oeditus/ragex.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("ragex").setup({
        ragex_path = vim.fn.expand("/opt/ragex"),
      })
    end,
  },
}
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Oeditus/ragex.nvim ~/.local/share/nvim/site/pack/plugins/start/ragex.nvim
   ```

2. Add to your init.lua:
   ```lua
   require("ragex").setup()
   ```

## Quick Start

1. Start Ragex MCP server:
   ```bash
   cd ~/path/to/ragex
   mix run --no-halt > /tmp/ragex.log 2>&1 &
   ```

2. Open NeoVim in your Elixir project

3. Analyze project:
   ```vim
   :Ragex analyze_directory
   ```

4. Try semantic search:
   ```vim
   :Ragex search
   ```

## Commands

All commands are available via `:Ragex <subcommand>`:

### Search & Navigation
- `:Ragex search` - Semantic search with Telescope UI
- `:Ragex search_word` - Search word under cursor
- `:Ragex functions` - Find functions by description
- `:Ragex modules` - Find modules by description
- `:Ragex find_callers` - Show all callers of function under cursor
- `:Ragex find_paths` - Find call chains between functions

### Analysis
- `:Ragex analyze_file` - Analyze current file
- `:Ragex analyze_directory` - Analyze entire project
- `:Ragex watch_directory` - Enable auto-reindex on file changes
- `:Ragex graph_stats` - Show knowledge graph statistics
- `:Ragex toggle_auto` - Toggle auto-analysis on save

### Refactoring
- `:Ragex rename_function` - Rename function (project-wide)
- `:Ragex rename_module` - Rename module (project-wide)
- `:Ragex extract_function` - Extract code range into new function
- `:Ragex inline_function` - Inline function at all call sites
- `:Ragex change_signature` - Add/remove/reorder parameters
- `:Ragex convert_visibility` - Toggle def/defp
- `:Ragex rename_parameter` - Rename function parameter
- `:Ragex modify_attributes` - Add/remove module attributes

### Code Quality
- `:Ragex find_duplicates` - Find duplicate code (AST-based)
- `:Ragex find_similar` - Find semantically similar code
- `:Ragex find_dead_code` - Find unused functions
- `:Ragex analyze_dependencies` - Show dependency graph
- `:Ragex coupling_report` - Show coupling metrics
- `:Ragex quality_report` - Comprehensive quality analysis

### Impact Analysis
- `:Ragex analyze_impact` - Analyze function importance
- `:Ragex estimate_effort` - Estimate refactoring effort
- `:Ragex risk_assessment` - Assess change risk

### Graph Algorithms
- `:Ragex betweenness_centrality` - Find bridge/bottleneck functions
- `:Ragex closeness_centrality` - Find central functions
- `:Ragex detect_communities` - Discover architectural modules
- `:Ragex export_graph` - Export visualization (Graphviz/D3)

## Default Keybindings

The plugin does not set keybindings by default. Here's a suggested configuration:

```lua
-- Search
vim.keymap.set("n", "<leader>rs", "<cmd>Ragex search<cr>", { desc = "Ragex: Semantic Search" })
vim.keymap.set("n", "<leader>rw", "<cmd>Ragex search_word<cr>", { desc = "Ragex: Search Word" })
vim.keymap.set("n", "<leader>rf", "<cmd>Ragex functions<cr>", { desc = "Ragex: Find Functions" })
vim.keymap.set("n", "<leader>rm", "<cmd>Ragex modules<cr>", { desc = "Ragex: Find Modules" })

-- Analysis
vim.keymap.set("n", "<leader>ra", "<cmd>Ragex analyze_file<cr>", { desc = "Ragex: Analyze File" })
vim.keymap.set("n", "<leader>rd", "<cmd>Ragex analyze_directory<cr>", { desc = "Ragex: Analyze Directory" })
vim.keymap.set("n", "<leader>rc", "<cmd>Ragex find_callers<cr>", { desc = "Ragex: Find Callers" })
vim.keymap.set("n", "<leader>rg", "<cmd>Ragex graph_stats<cr>", { desc = "Ragex: Graph Stats" })

-- Refactoring
vim.keymap.set("n", "<leader>rr", "<cmd>Ragex rename_function<cr>", { desc = "Ragex: Rename Function" })
vim.keymap.set("n", "<leader>rR", "<cmd>Ragex rename_module<cr>", { desc = "Ragex: Rename Module" })
vim.keymap.set("n", "<leader>re", "<cmd>Ragex extract_function<cr>", { desc = "Ragex: Extract Function" })
vim.keymap.set("n", "<leader>ri", "<cmd>Ragex inline_function<cr>", { desc = "Ragex: Inline Function" })

-- Quality
vim.keymap.set("n", "<leader>rD", "<cmd>Ragex find_duplicates<cr>", { desc = "Ragex: Find Duplicates" })
vim.keymap.set("n", "<leader>rS", "<cmd>Ragex find_similar<cr>", { desc = "Ragex: Find Similar Code" })
vim.keymap.set("n", "<leader>rX", "<cmd>Ragex find_dead_code<cr>", { desc = "Ragex: Find Dead Code" })
vim.keymap.set("n", "<leader>rQ", "<cmd>Ragex quality_report<cr>", { desc = "Ragex: Quality Report" })

-- Graph Algorithms
vim.keymap.set("n", "<leader>rb", "<cmd>Ragex betweenness_centrality<cr>", { desc = "Ragex: Betweenness" })
vim.keymap.set("n", "<leader>ro", "<cmd>Ragex closeness_centrality<cr>", { desc = "Ragex: Closeness" })
vim.keymap.set("n", "<leader>rn", "<cmd>Ragex detect_communities<cr>", { desc = "Ragex: Communities" })
```

## Configuration

Full configuration options:

```lua
require("ragex").setup({
  -- Path to Ragex installation
  ragex_path = vim.fn.expand("~/path/to/ragex"),
  
  -- Enable/disable plugin
  enabled = true,
  
  -- Enable debug logging
  debug = false,
  
  -- Auto-analyze files on save
  auto_analyze = false,
  
  -- Analyze project on startup
  auto_analyze_on_start = false,
  
  -- Additional directories to analyze on startup
  auto_analyze_dirs = {},
  
  -- Default search options
  search = {
    limit = 50,          -- Max results
    threshold = 0.2,     -- Similarity threshold (0.0-1.0)
    strategy = "fusion", -- "fusion", "semantic_first", "graph_first"
  },
  
  -- Socket connection
  socket_path = "/tmp/ragex_mcp.sock",
  
  -- Timeout for operations (milliseconds)
  timeout = {
    default = 60000,      -- 60 seconds
    analyze = 120000,     -- 120 seconds for directory analysis
    search = 30000,       -- 30 seconds for searches
  },
  
  -- Telescope UI options
  telescope = {
    theme = "dropdown",           -- "dropdown", "ivy", "cursor"
    previewer = true,             -- Enable file preview
    show_score = true,            -- Show similarity scores
    layout_config = {
      width = 0.8,
      height = 0.9,
    },
  },
  
  -- Status line integration
  statusline = {
    enabled = true,
    symbol = " Ragex",
  },
  
  -- Progress notifications
  notifications = {
    enabled = true,
    verbose = false,  -- Show detailed progress
  },
})
```

## Usage Examples

### 1. Semantic Code Search

Find code by description:

```vim
:Ragex search
" Type: "user authentication and login"
" Results show ranked by semantic similarity
```

### 2. Safe Project-Wide Refactoring

Rename function everywhere:

```vim
" Place cursor on function definition
:Ragex rename_function
" Enter new name: fetch_user
" Ragex updates all call sites, validates syntax, formats code
```

### 3. Find All Callers

```vim
" Place cursor on function name
:Ragex find_callers
" View callers in floating window
```

### 4. Code Duplication Detection

```vim
:Ragex find_duplicates
" Shows AST-based duplicate code blocks
" Type I-IV clones: exact, renamed, near-miss, semantic
```

### 5. Impact Analysis

```vim
" Place cursor on function
:Ragex analyze_impact
" Shows:
" - Importance score
" - Direct/indirect dependents
" - Risk level
" - Suggested tests
```

### 6. Community Detection

Discover architectural modules:

```vim
:Ragex detect_communities
" Shows cohesive groups of functions
" Useful for refactoring, microservices planning
```

## Architecture

The plugin consists of several modules:

- **core.lua**: Main plugin logic, MCP client, configuration
- **commands.lua**: Vim command definitions
- **telescope.lua**: Telescope picker integrations
- **ui.lua**: Floating windows, notifications, progress bars
- **refactor.lua**: Refactoring operation handlers
- **analysis.lua**: Code quality and analysis features
- **graph.lua**: Graph algorithm visualizations
- **utils.lua**: Helper functions, parsing utilities

## Troubleshooting

### "Failed to parse Ragex response"

Ragex server not running or socket not accessible.

**Solution**:
```bash
# Check if running
ps aux | grep "mix run"

# Start server
cd ~/path/to/ragex && mix run --no-halt &

# Test socket
echo '{"jsonrpc":"2.0","method":"tools/list","id":1}' | socat - UNIX-CONNECT:/tmp/ragex_mcp.sock
```

### "No results found"

Project not analyzed yet.

**Solution**:
```vim
:Ragex analyze_directory
```

### Slow searches

First search builds embeddings cache.

**Solution**: Wait for first search to complete. Subsequent searches will be fast (<100ms).

### Socket connection timeout

Long-running operations may timeout.

**Solution**: Increase timeout in configuration:
```lua
require("ragex").setup({
  timeout = {
    analyze = 300000,  -- 5 minutes
  },
})
```

## Performance

- Cold start: ~2-3 seconds (first Ragex call)
- Search: <100ms typical (with cache)
- Analysis: ~100 files/second
- Centrality algorithms: <200ms for 1000 nodes
- Community detection: <1s for 10000 nodes

## Development

Run tests:
```bash
cd nvim-plugin
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
```

Lint:
```bash
luacheck lua/
stylua lua/ --check
```

## Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new features
4. Ensure all tests pass
5. Submit pull request

## License

MIT

## Related Projects

- [Ragex](https://github.com/Oeditus/ragex) - The MCP server powering this plugin
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - Fuzzy finder UI
- [LunarVim](https://www.lunarvim.org/) - NeoVim distribution

## Credits

Created by Aleksei Matiushkin (@Oeditus)

Built on top of:
- Elixir/OTP ecosystem
- Bumblebee ML framework
- MCP (Model Context Protocol)

# Ragex Quick Start Guide

Get up and running with Ragex in LunarVim in 5 minutes.

## Installation Complete ✓

Ragex integration is now installed in your LunarVim config!

Files created:
- `~/.config/lvim/lua/user/ragex.lua`
- `~/.config/lvim/lua/user/ragex_telescope.lua`
- `~/.config/lvim/config.lua` (updated)

## Quick Start (5 steps)

### 1. Start Ragex Server

Open a terminal and run:
```bash
cd ~/Proyectos/Ammotion/ragex
mix run --no-halt &
```

This starts Ragex in the background. You can close the terminal.

**Tip**: Add to your `~/.zshrc` to auto-start:
```bash
alias ragex-start='cd ~/Proyectos/Ammotion/ragex && mix run --no-halt > /tmp/ragex.log 2>&1 &'
```

### 2. Restart LunarVim

Close and reopen LunarVim, or run:
```vim
:source ~/.config/lvim/config.lua
```

You should see " Ragex" in your status line (bottom right).

### 3. Open an Elixir Project

```bash
cd ~/path/to/your/elixir/project
lvim lib/your_module.ex
```

### 4. Analyze Your Project

Press `<space>rd` (Space + r + d)

Wait for notification: "Analyzed X files"

**This is a one-time setup per project.**

### 5. Try Semantic Search

Press `<space>rs` (Space + r + s)

Type a query like: "user authentication"

Browse results with arrow keys, press Enter to jump to code.

**That's it! You're ready to go.**

---

## Essential Keybindings (Cheat Sheet)

Save this for reference:

### Search (most used)
```
<space>rs   - Semantic search (type what you're looking for)
<space>rw   - Search word under cursor
<space>rf   - Find functions
<space>rm   - Find modules
```

### Navigation
```
<space>rc   - Find callers of function under cursor
```

### Refactoring
```
<space>rr   - Rename function (project-wide)
<space>rR   - Rename module (project-wide)
```

### Analysis
```
<space>ra   - Analyze current file
<space>rd   - Analyze directory (do this once per project)
<space>rW   - Watch directory (auto-reindex on changes)
<space>rt   - Toggle auto-analysis on save
```

---

## Usage Examples

### Example 1: Find Code by Description

**Goal**: Find functions that validate email addresses

1. Press `<space>rs`
2. Type: `email validation`
3. See results ranked by relevance
4. Press Enter to jump to code

### Example 2: Understand Function Usage

**Goal**: See where `process_order/2` is called

1. Place cursor on `process_order`
2. Press `<space>rc`
3. See all callers in floating window

### Example 3: Safe Rename

**Goal**: Rename `get_user/1` to `fetch_user/1` everywhere

1. Cursor on `get_user` definition
2. Press `<space>rr`
3. Type: `fetch_user`
4. Done! All files updated, validated, formatted

---

## Troubleshooting

### "No results found"

Run: `<space>rd` to analyze your project first.

### "Failed to parse Ragex response" or "Invalid response format"

**Cause**: Ragex server not running or not responding correctly.

**Solution**:

1. Check if Ragex is running:
   ```bash
   ps aux | grep "mix run"
   ```

2. If not running, start it:
   ```bash
   cd ~/Proyectos/Ammotion/ragex && mix run --no-halt > /tmp/ragex.log 2>&1 &
   ```

3. Check logs for errors:
   ```bash
   tail -f /tmp/ragex.log
   ```

4. Test manually:
   ```bash
   cd ~/Proyectos/Ammotion/ragex
   echo '{"jsonrpc":"2.0","method":"tools/list","id":1}' | mix run --no-halt
   ```

### Commands don't work

Make sure you restarted LunarVim after installation.

### Enable debug logging

To see what's happening:
```lua
:lua require('user.ragex').config.debug = true
```

Then check Neovim messages: `:messages`

---

## Auto-Analysis

**Auto-analysis is OFF by default.** To enable:

- Press `<space>rt` to toggle on/off, OR
- Run `:RagexToggleAuto`, OR  
- Add to config:
  ```lua
  ragex.setup({ auto_analyze = true })
  ```

## Daily Workflow

1. **Morning**: Start Ragex server (`ragex-start` alias)
2. **Open project**: Manually analyze once with `<space>rd`
3. **Search**: Use `<space>rs` when looking for code
4. **Refactor**: Use `<space>rr` to rename safely
5. **Navigate**: Use `<space>rc` to find callers
6. **Optional**: Enable auto-analysis with `<space>rt`

---

## Next Steps

- Read full docs: `~/.config/lvim/RAGEX_INTEGRATION.md`
- Check Ragex features: `~/Proyectos/Ammotion/ragex/stuff/docs/USAGE.md`
- Experiment with semantic search
- Try project-wide refactoring

---

## Support

- **Issues**: Check Ragex logs: `/tmp/ragex.log`
- **Questions**: See `RAGEX_INTEGRATION.md`
- **LunarVim**: `:help` or https://lunarvim.org

---

**Enjoy coding with AI-powered semantic search!** 🚀

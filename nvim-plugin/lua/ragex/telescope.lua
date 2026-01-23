-- Telescope integration for ragex.nvim
-- Beautiful search UI for semantic code search and navigation

local M = {}

-- Check if Telescope is available
local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  return M
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

local core = require("ragex.core")
local utils = require("ragex.utils")
local ui = require("ragex.ui")

-- Create entry displayer for search results
local function create_displayer(opts)
  opts = opts or {}
  
  return entry_display.create({
    separator = " │ ",
    items = {
      { width = 6 },  -- Score
      { width = 50 }, -- Description
      { remaining = true }, -- File
    },
  })
end

-- Format search result entry
local function make_entry(opts)
  opts = opts or {}
  local displayer = create_displayer(opts)
  
  return function(entry)
    local score = entry.score or 0
    local display_text = entry.description or entry.text or ""
    local file = (entry.context and entry.context.file) or entry.file or "unknown"
    local line = (entry.context and entry.context.line) or entry.line or 1
    
    return {
      value = entry,
      display = function(ent)
        return displayer({
          { string.format("%.3f", score), "TelescopeResultsNumber" },
          { utils.truncate(display_text, 48), "TelescopeResultsIdentifier" },
          { file, "TelescopeResultsComment" },
        })
      end,
      ordinal = display_text .. " " .. file,
      filename = file,
      lnum = line,
    }
  end
end

-- Generic search picker
local function search_picker(prompt_title, query, method, opts)
  opts = opts or {}
  
  local loading = ui.notify_loading("Searching...")
  
  core.execute(method, { query = query, limit = 50, node_type = opts.node_type }, function(result, error_type)
    ui.dismiss_notification(loading)
    
    if error_type == "timeout" then
      ui.notify("Search timed out (try again, embeddings will cache)", "warn")
      return
    end
    
    if error_type then
      ui.notify("Search failed: " .. error_type, "error")
      return
    end
    
    local data, err = utils.parse_mcp_response(result)
    if err then
      ui.notify("Search failed: " .. err, "error")
      return
    end
    
    if not data.results or #data.results == 0 then
      ui.notify("No results found", "warn")
      return
    end
    
    vim.schedule(function()
      pickers.new(opts, {
        prompt_title = prompt_title,
        finder = finders.new_table({
          results = data.results,
          entry_maker = make_entry(opts),
        }),
        sorter = conf.generic_sorter(opts),
        previewer = conf.grep_previewer(opts),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection and selection.filename and selection.lnum then
              vim.cmd(string.format("edit +%d %s", selection.lnum, selection.filename))
            end
          end)
          return true
        end,
      }):find()
    end)
  end)
end

-- Semantic search picker
function M.search()
  ui.input("Ragex Search: ", {}, function(query)
    if not query then return end
    search_picker("Ragex Search: " .. query, query, "hybrid_search")
  end)
end

-- Search word under cursor
function M.search_word()
  local word = utils.get_word_under_cursor()
  if not word or word == "" then
    ui.notify("No word under cursor", "warn")
    return
  end
  
  search_picker("Ragex Search: " .. word, word, "hybrid_search")
end

-- Find functions
function M.functions()
  ui.input("Find functions: ", {}, function(query)
    if not query then return end
    search_picker("Ragex Functions: " .. query, query, "semantic_search", { node_type = "function" })
  end)
end

-- Find modules
function M.modules()
  ui.input("Find modules: ", {}, function(query)
    if not query then return end
    search_picker("Ragex Modules: " .. query, query, "semantic_search", { node_type = "module" })
  end)
end

-- Show callers in Telescope
function M.callers()
  local module = utils.get_current_module()
  if not module then
    ui.notify("Could not determine current module", "warn")
    return
  end
  
  local func_name, arity = utils.get_function_under_cursor()
  if not func_name then
    ui.notify("Could not determine function name", "warn")
    return
  end
  
  local loading = ui.notify_loading("Finding callers...")
  
  local params = {
    module = module,
    function_name = func_name,
  }
  if arity then
    params.arity = arity
  end
  
  core.execute("find_callers", params, function(result, error_type)
    ui.dismiss_notification(loading)
    
    if error_type then
      ui.notify("Failed to find callers: " .. error_type, "error")
      return
    end
    
    local data, err = utils.parse_mcp_response(result)
    if err then
      ui.notify("Failed to parse callers: " .. err, "error")
      return
    end
    
    if not data.callers or #data.callers == 0 then
      ui.notify("No callers found", "warn")
      return
    end
    
    vim.schedule(function()
      pickers.new({}, {
        prompt_title = string.format("Callers of %s.%s/%s", module, func_name, arity or "?"),
        finder = finders.new_table({
          results = data.callers,
          entry_maker = function(caller)
            local display_text = caller.caller_id or caller.id or "unknown"
            local file = caller.file or "unknown"
            local line = caller.line or 1
            
            return {
              value = caller,
              display = string.format("%s (%s:%d)", display_text, file, line),
              ordinal = display_text,
              filename = file,
              lnum = line,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        previewer = conf.grep_previewer({}),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection and selection.filename and selection.lnum then
              vim.cmd(string.format("edit +%d %s", selection.lnum, selection.filename))
            end
          end)
          return true
        end,
      }):find()
    end)
  end)
end

-- Show duplicates in Telescope
function M.duplicates(opts)
  opts = opts or {}
  
  local loading = ui.notify_loading("Finding duplicates...")
  
  core.execute("find_duplicates", opts, function(result, error_type)
    ui.dismiss_notification(loading)
    
    if error_type then
      ui.notify("Failed to find duplicates: " .. error_type, "error")
      return
    end
    
    local data, err = utils.parse_mcp_response(result)
    if err then
      ui.notify("Failed to parse duplicates: " .. err, "error")
      return
    end
    
    if not data.clones or #data.clones == 0 then
      ui.notify("No duplicates found", "info")
      return
    end
    
    -- Flatten clones for picker
    local entries = {}
    for _, clone in ipairs(data.clones) do
      for _, location in ipairs(clone.locations or {}) do
        table.insert(entries, {
          type = clone.type,
          similarity = clone.similarity,
          file = location.file,
          line = location.line,
          snippet = location.snippet or "",
        })
      end
    end
    
    vim.schedule(function()
      pickers.new({}, {
        prompt_title = string.format("Code Duplicates (%d clones)", #data.clones),
        finder = finders.new_table({
          results = entries,
          entry_maker = function(entry)
            local display_text = string.format("[%s] %.2f%% - %s", 
              entry.type, 
              (entry.similarity or 0) * 100,
              utils.truncate(entry.snippet, 60))
            
            return {
              value = entry,
              display = display_text,
              ordinal = display_text,
              filename = entry.file,
              lnum = entry.line,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        previewer = conf.grep_previewer({}),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection and selection.filename and selection.lnum then
              vim.cmd(string.format("edit +%d %s", selection.lnum, selection.filename))
            end
          end)
          return true
        end,
      }):find()
    end)
  end)
end

-- Show dead code in Telescope
function M.dead_code(opts)
  opts = opts or {}
  
  local loading = ui.notify_loading("Finding dead code...")
  
  core.execute("find_dead_code", opts, function(result, error_type)
    ui.dismiss_notification(loading)
    
    if error_type then
      ui.notify("Failed to find dead code: " .. error_type, "error")
      return
    end
    
    local data, err = utils.parse_mcp_response(result)
    if err then
      ui.notify("Failed to parse dead code: " .. err, "error")
      return
    end
    
    if not data.dead_functions or #data.dead_functions == 0 then
      ui.notify("No dead code found", "info")
      return
    end
    
    vim.schedule(function()
      pickers.new({}, {
        prompt_title = string.format("Dead Code (%d functions)", #data.dead_functions),
        finder = finders.new_table({
          results = data.dead_functions,
          entry_maker = function(func)
            local display_text = func.id or "unknown"
            local file = func.file or "unknown"
            local line = func.line or 1
            
            return {
              value = func,
              display = string.format("%s (%s:%d)", display_text, file, line),
              ordinal = display_text,
              filename = file,
              lnum = line,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        previewer = conf.grep_previewer({}),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection and selection.filename and selection.lnum then
              vim.cmd(string.format("edit +%d %s", selection.lnum, selection.filename))
            end
          end)
          return true
        end,
      }):find()
    end)
  end)
end

return M

-- Telescope integration for Ragex
-- Provides beautiful search UI for semantic code search

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

-- Ragex semantic search with Telescope
function M.ragex_search()
  vim.ui.input({ prompt = "Ragex Search: " }, function(query)
    if not query or query == "" then
      return
    end

    local ragex = require("user.ragex")
    
    -- Show loading notification
    local loading = vim.notify("Searching...", vim.log.levels.INFO, {
      timeout = false,
      hide_from_history = true,
    })

    ragex.execute("hybrid_search", { query = query, limit = 50 }, function(result, error_type)
      -- Dismiss loading notification
      if loading then
        vim.notify("", vim.log.levels.INFO, { replace = loading, timeout = 1 })
      end

      -- Handle timeout
      if error_type == "timeout" then
        vim.notify("✗ Ragex: Search timed out (try again, embeddings will cache)", vim.log.levels.WARN)
        return
      end

      -- Handle other errors
      if error_type == "error" or error_type == "parse_error" then
        vim.notify("✗ Ragex: Search failed", vim.log.levels.ERROR)
        return
      end

      if not result or not result.result then
        vim.notify("No results found", vim.log.levels.WARN)
        return
      end

      -- Unwrap MCP response
      local data = result.result
      if data.content and data.content[1] and data.content[1].text then
        local ok, parsed = pcall(vim.fn.json_decode, data.content[1].text)
        if ok then
          data = parsed
        end
      end

      if not data.results then
        vim.notify("No results found", vim.log.levels.WARN)
        return
      end

      local entries = {}
      for _, item in ipairs(data.results) do
        local display_text = item.description or item.text or ""
        local file = (item.context and item.context.file) or item.file or "unknown"
        local line = (item.context and item.context.line) or item.line or 1
        local score = item.score or 0

        table.insert(entries, {
          value = item,
          display = string.format("[%.2f] %s", score, display_text),
          ordinal = display_text,
          filename = file,
          lnum = line,
        })
      end

      if #entries == 0 then
        vim.notify("No results found", vim.log.levels.WARN)
        return
      end

      pickers.new({}, {
        prompt_title = "Ragex Search: " .. query,
        finder = finders.new_table({
          results = entries,
          entry_maker = function(entry)
            return entry
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

-- Find functions with semantic search
function M.ragex_functions()
  vim.ui.input({ prompt = "Find functions: " }, function(query)
    if not query or query == "" then
      return
    end

    local ragex = require("user.ragex")
    
    ragex.execute("semantic_search", {
      query = query,
      limit = 50,
      node_type = "function",
    }, function(result, error_type)
      -- Handle timeout
      if error_type == "timeout" then
        vim.notify("✗ Ragex: Search timed out (try again, embeddings will cache)", vim.log.levels.WARN)
        return
      end

      -- Handle other errors
      if error_type == "error" or error_type == "parse_error" then
        vim.notify("✗ Ragex: Search failed", vim.log.levels.ERROR)
        return
      end

      if not result or not result.result then
        vim.notify("No functions found", vim.log.levels.WARN)
        return
      end

      -- Unwrap MCP response
      local data = result.result
      if data.content and data.content[1] and data.content[1].text then
        local ok, parsed = pcall(vim.fn.json_decode, data.content[1].text)
        if ok then
          data = parsed
        end
      end

      if not data.results then
        vim.notify("No functions found", vim.log.levels.WARN)
        return
      end

      local entries = {}
      for _, item in ipairs(data.results) do
        -- Parse node_id string like "Elixir.Module.function/2"
        local node_id_str = item.node_id or ""
        local display_text = item.description or node_id_str
        local file = (item.context and item.context.file) or item.file or "unknown"
        local line = (item.context and item.context.line) or item.line or 1
        local score = item.score or 0

        table.insert(entries, {
          value = item,
          display = string.format("[%.2f] %s", score, display_text),
          ordinal = display_text,
          filename = file,
          lnum = line,
        })
      end

      if #entries == 0 then
        vim.notify("No functions found", vim.log.levels.WARN)
        return
      end

      pickers.new({}, {
        prompt_title = "Ragex Functions: " .. query,
        finder = finders.new_table({
          results = entries,
          entry_maker = function(entry)
            return entry
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

-- Find modules with semantic search
function M.ragex_modules()
  vim.ui.input({ prompt = "Find modules: " }, function(query)
    if not query or query == "" then
      return
    end

    local ragex = require("user.ragex")
    
    ragex.execute("semantic_search", {
      query = query,
      limit = 50,
      node_type = "module",
    }, function(result, error_type)
      -- Handle timeout
      if error_type == "timeout" then
        vim.notify("✗ Ragex: Search timed out (try again, embeddings will cache)", vim.log.levels.WARN)
        return
      end

      -- Handle other errors
      if error_type == "error" or error_type == "parse_error" then
        vim.notify("✗ Ragex: Search failed", vim.log.levels.ERROR)
        return
      end

      if not result or not result.result then
        vim.notify("No modules found", vim.log.levels.WARN)
        return
      end

      -- Unwrap MCP response
      local data = result.result
      if data.content and data.content[1] and data.content[1].text then
        local ok, parsed = pcall(vim.fn.json_decode, data.content[1].text)
        if ok then
          data = parsed
        end
      end

      if not data.results then
        vim.notify("No modules found", vim.log.levels.WARN)
        return
      end

      local entries = {}
      for _, item in ipairs(data.results) do
        local node_id_str = item.node_id or ""
        local display_text = item.description or node_id_str
        local file = (item.context and item.context.file) or item.file or "unknown"
        local line = (item.context and item.context.line) or item.line or 1
        local score = item.score or 0

        table.insert(entries, {
          value = item,
          display = string.format("[%.2f] %s", score, display_text),
          ordinal = display_text,
          filename = file,
          lnum = line,
        })
      end

      if #entries == 0 then
        vim.notify("No modules found", vim.log.levels.WARN)
        return
      end

      pickers.new({}, {
        prompt_title = "Ragex Modules: " .. query,
        finder = finders.new_table({
          results = entries,
          entry_maker = function(entry)
            return entry
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

-- Search for word under cursor
function M.ragex_search_word()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    vim.notify("No word under cursor", vim.log.levels.WARN)
    return
  end

  local ragex = require("user.ragex")
  
  ragex.execute("hybrid_search", { query = word, limit = 50 }, function(result, error_type)
    -- Handle timeout
    if error_type == "timeout" then
      vim.notify("✗ Ragex: Search timed out for '" .. word .. "' (try again, embeddings will cache)", vim.log.levels.WARN)
      return
    end

    -- Handle other errors
    if error_type == "error" or error_type == "parse_error" then
      vim.notify("✗ Ragex: Search failed for '" .. word .. "'", vim.log.levels.ERROR)
      return
    end

    if not result or not result.result then
      vim.notify("No results found for: " .. word, vim.log.levels.WARN)
      return
    end

    -- Unwrap MCP response
    local data = result.result
    if data.content and data.content[1] and data.content[1].text then
      local ok, parsed = pcall(vim.fn.json_decode, data.content[1].text)
      if ok then
        data = parsed
      end
    end

    if not data.results then
      vim.notify("No results found for: " .. word, vim.log.levels.WARN)
      return
    end

    local entries = {}
    for _, item in ipairs(data.results) do
      local display_text = item.description or item.text or ""
      local file = (item.context and item.context.file) or item.file or "unknown"
      local line = (item.context and item.context.line) or item.line or 1
      local score = item.score or 0

      table.insert(entries, {
        value = item,
        display = string.format("[%.2f] %s", score, display_text),
        ordinal = display_text,
        filename = file,
        lnum = line,
      })
    end

    if #entries == 0 then
      vim.notify("No results found for: " .. word, vim.log.levels.WARN)
      return
    end

    pickers.new({}, {
      prompt_title = "Ragex Search: " .. word,
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return entry
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
end

return M

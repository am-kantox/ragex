-- RAG (Retrieval-Augmented Generation) features for ragex.nvim

local M = {}
local core = require("ragex.core")
local utils = require("ragex.utils")
local ui = require("ragex.ui")

-- Helper to execute RAG query
local function execute_rag(method, params, title, on_complete)
  local loading = ui.notify_loading("Processing RAG query...")
  
  core.execute(method, params or {}, function(result, error_type)
    ui.dismiss_notification(loading)
    
    if error_type then
      ui.notify("RAG query failed: " .. error_type, "error")
      return
    end
    
    local data, err = utils.parse_mcp_response(result)
    if err then
      ui.notify("RAG query failed: " .. err, "error")
      return
    end
    
    if on_complete then
      on_complete(data)
    else
      ui.show_float({vim.inspect(data)}, { title = title or "RAG Result" })
    end
  end)
end

-- RAG query (streaming)
function M.rag_query_stream(query, opts)
  opts = opts or {}
  opts.query = query
  
  if not query then
    ui.input("Enter query: ", {}, function(input)
      if input then
        M.rag_query_stream(input, opts)
      end
    end)
    return
  end
  
  -- For streaming, we show results as they arrive
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.8),
    row = math.floor(vim.o.lines * 0.1),
    col = math.floor(vim.o.columns * 0.1),
    style = "minimal",
    border = "rounded",
    title = " RAG Query (Streaming) ",
  })
  
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  
  execute_rag("rag_query_stream", opts, "RAG Query", function(data)
    local lines = vim.split(data.response or vim.inspect(data), "\n")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end)
end

-- RAG query (non-streaming)
function M.rag_query(query, opts)
  opts = opts or {}
  opts.query = query
  
  if not query then
    ui.input("Enter query: ", {}, function(input)
      if input then
        M.rag_query(input, opts)
      end
    end)
    return
  end
  
  execute_rag("rag_query", opts, "RAG Query", function(data)
    local lines = vim.split(data.response or vim.inspect(data), "\n")
    ui.show_float(lines, { title = "RAG Query Result" })
  end)
end

-- RAG explain (streaming)
function M.rag_explain_stream(code_location, opts)
  opts = opts or {}
  
  if not code_location then
    local module = utils.get_current_module()
    local func_name, arity = utils.get_function_under_cursor()
    
    if module and func_name then
      code_location = string.format("%s.%s/%s", module, func_name, arity or "?")
    else
      ui.notify("Could not determine code location", "warn")
      return
    end
  end
  
  opts.code_location = code_location
  
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.8),
    row = math.floor(vim.o.lines * 0.1),
    col = math.floor(vim.o.columns * 0.1),
    style = "minimal",
    border = "rounded",
    title = " RAG Explanation (Streaming) ",
  })
  
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  
  execute_rag("rag_explain_stream", opts, "RAG Explain", function(data)
    local lines = vim.split(data.explanation or vim.inspect(data), "\n")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end)
end

-- RAG explain (non-streaming)
function M.rag_explain(code_location, opts)
  opts = opts or {}
  
  if not code_location then
    local module = utils.get_current_module()
    local func_name, arity = utils.get_function_under_cursor()
    
    if module and func_name then
      code_location = string.format("%s.%s/%s", module, func_name, arity or "?")
    else
      ui.notify("Could not determine code location", "warn")
      return
    end
  end
  
  opts.code_location = code_location
  
  execute_rag("rag_explain", opts, "RAG Explain", function(data)
    local lines = vim.split(data.explanation or vim.inspect(data), "\n")
    ui.show_float(lines, { title = "RAG Explanation" })
  end)
end

-- RAG suggest (streaming)
function M.rag_suggest_stream(context, opts)
  opts = opts or {}
  
  if not context then
    context = utils.get_visual_selection() or ""
    if context == "" then
      ui.input("Enter context: ", {}, function(input)
        if input then
          M.rag_suggest_stream(input, opts)
        end
      end)
      return
    end
  end
  
  opts.context = context
  
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.8),
    row = math.floor(vim.o.lines * 0.1),
    col = math.floor(vim.o.columns * 0.1),
    style = "minimal",
    border = "rounded",
    title = " RAG Suggestions (Streaming) ",
  })
  
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  
  execute_rag("rag_suggest_stream", opts, "RAG Suggest", function(data)
    local lines = vim.split(data.suggestions or vim.inspect(data), "\n")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end)
end

-- RAG suggest (non-streaming)
function M.rag_suggest(context, opts)
  opts = opts or {}
  
  if not context then
    context = utils.get_visual_selection() or ""
    if context == "" then
      ui.input("Enter context: ", {}, function(input)
        if input then
          M.rag_suggest(input, opts)
        end
      end)
      return
    end
  end
  
  opts.context = context
  
  execute_rag("rag_suggest", opts, "RAG Suggest", function(data)
    local lines = vim.split(data.suggestions or vim.inspect(data), "\n")
    ui.show_float(lines, { title = "RAG Suggestions" })
  end)
end

-- Query expansion
function M.expand_query(query)
  if not query then
    ui.input("Enter query to expand: ", {}, function(input)
      if input then
        M.expand_query(input)
      end
    end)
    return
  end
  
  execute_rag("expand_query", {query = query}, "Expanded Query", function(data)
    local lines = {
      "Original: " .. query,
      "",
      "Expanded queries:",
    }
    
    if data.expanded_queries then
      for i, q in ipairs(data.expanded_queries) do
        table.insert(lines, string.format("%d. %s", i, q))
      end
    end
    
    ui.show_float(lines, { title = "Query Expansion" })
  end)
end

-- Cross-language alternatives
function M.cross_language_alternatives(code_location, opts)
  opts = opts or {}
  
  if not code_location then
    local module = utils.get_current_module()
    local func_name, arity = utils.get_function_under_cursor()
    
    if module and func_name then
      code_location = string.format("%s.%s/%s", module, func_name, arity or "?")
    else
      ui.notify("Could not determine code location", "warn")
      return
    end
  end
  
  opts.code_location = code_location
  
  execute_rag("cross_language_alternatives", opts, "Cross-Language Alternatives")
end

-- MetaAST search
function M.metaast_search(pattern, opts)
  opts = opts or {}
  opts.pattern = pattern
  
  if not pattern then
    ui.input("Enter MetaAST pattern: ", {}, function(input)
      if input then
        M.metaast_search(input, opts)
      end
    end)
    return
  end
  
  execute_rag("metaast_search", opts, "MetaAST Search")
end

-- Find MetaAST pattern
function M.find_metaast_pattern(pattern_type, opts)
  opts = opts or {}
  opts.pattern_type = pattern_type
  
  if not pattern_type then
    ui.select({"function_definition", "function_call", "conditional", "loop", "assignment"}, {
      prompt = "Select pattern type:",
    }, function(choice)
      if choice then
        M.find_metaast_pattern(choice, opts)
      end
    end)
    return
  end
  
  execute_rag("find_metaast_pattern", opts, "MetaAST Pattern Results")
end

return M

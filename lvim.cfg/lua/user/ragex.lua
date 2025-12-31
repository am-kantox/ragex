-- Ragex Integration for LunarVim
-- Provides semantic code search, refactoring, and analysis for Elixir projects

local M = {}

-- Configuration
M.config = {
  project_root = vim.fn.getcwd(),
  ragex_path = vim.fn.expand("~/Proyectos/Ammotion/ragex"),
  enabled = true,
  debug = true,  -- Enable to see request/response logs
  auto_analyze = false,  -- Disabled by default, enable with :lua require('user.ragex').config.auto_analyze = true
}

-- Log debug messages
local function debug_log(msg)
  if M.config.debug then
    vim.notify("[Ragex] " .. msg, vim.log.levels.INFO)
  end
end

-- Execute Ragex MCP command
function M.execute(method, params, callback)
  if not M.config.enabled then
    debug_log("Ragex is disabled")
    return
  end

  local request = vim.fn.json_encode({
    jsonrpc = "2.0",
    method = "tools/call",
    params = {
      name = method,
      arguments = params,
    },
    id = vim.fn.rand(),
  })

  debug_log("Request JSON: " .. request)

  -- Connect to persistent socket server  
  -- Use socat in bidirectional mode with proper handling:
  -- The key issue is that socat needs to:
  -- 1. Send the request
  -- 2. Close the write side (so server knows request is complete)
  -- 3. But keep read side open to receive response
  -- 4. Wait for server to send response and close
  -- Using printf with proper quoting
  local cmd = string.format(
    "printf '%%s\\n' %s | socat - UNIX-CONNECT:/tmp/ragex_mcp.sock",
    vim.fn.shellescape(request)
  )

  debug_log("Executing: " .. method)
  debug_log("Command: " .. cmd)

  if callback then
    -- Async execution
    vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if data and #data > 0 then
          local result_str = table.concat(data, "\n")
          -- Clean up any trailing newlines or empty strings
          result_str = result_str:gsub("^%s+", ""):gsub("%s+$", "")
          
          if result_str ~= "" then
            debug_log("Response: " .. result_str:sub(1, 200))
            local ok, result = pcall(vim.fn.json_decode, result_str)
            if ok and result then
              callback(result)
            else
              debug_log("JSON parse error for: " .. result_str:sub(1, 100))
              vim.notify("Ragex: Invalid response format", vim.log.levels.WARN)
            end
          end
        end
      end,
      on_stderr = function(_, data)
        if data and #data > 0 then
          local err = table.concat(data, "\n")
          if err ~= "" and not err:match("^%s*$") then
            debug_log("Stderr: " .. err)
          end
        end
      end,
      on_exit = function(_, exit_code)
        if exit_code ~= 0 then
          debug_log("Command exited with code: " .. exit_code)
          vim.notify("Ragex: Command failed (check if server is running)", vim.log.levels.WARN)
        end
      end,
    })
  else
    -- Synchronous execution  
    debug_log("Command: " .. cmd)
    
    -- Use io.popen with socat (works reliably)
    local handle = io.popen(cmd)
    local result_str = ""
    
    if handle then
      result_str = handle:read("*a")
      handle:close()
    end
    
    debug_log("Raw response: " .. (result_str or "nil"))
    
    if result_str and result_str ~= "" then
      result_str = result_str:gsub("^%s+", ""):gsub("%s+$", "")
      debug_log("Cleaned response: " .. result_str:sub(1, 200))
      local ok, result = pcall(vim.fn.json_decode, result_str)
      if ok and result then
        debug_log("Parsed successfully")
        return result
      else
        debug_log("JSON parse failed: " .. tostring(result))
      end
    else
      debug_log("Empty or nil response")
    end
    
    return nil
  end
end

-- Semantic search
function M.semantic_search(query, opts)
  opts = opts or {}
  local params = {
    query = query,
    limit = opts.limit or 10,
    threshold = opts.threshold or 0.3,  -- Lower threshold for better recall
    node_type = opts.node_type,
  }

  return M.execute("semantic_search", params)
end

-- Hybrid search (best results)
function M.hybrid_search(query, opts)
  opts = opts or {}
  local params = {
    query = query,
    limit = opts.limit or 10,
    threshold = 0.3,  -- Lower threshold for better recall
    strategy = opts.strategy or "fusion",
  }

  return M.execute("hybrid_search", params)
end

-- Analyze current file
function M.analyze_current_file()
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    vim.notify("No file to analyze", vim.log.levels.WARN)
    return
  end

  M.execute("analyze_file", { path = filepath }, function(result)
    if result and result.result then
      vim.notify("File analyzed successfully", vim.log.levels.INFO)
    else
      vim.notify("Failed to analyze file", vim.log.levels.ERROR)
    end
  end)
end

-- Analyze directory
function M.analyze_directory(path, opts)
  opts = opts or {}
  path = path or vim.fn.getcwd()
  
  local params = {
    path = path,
    recursive = opts.recursive ~= false,
    parallel = opts.parallel ~= false,
    extensions = opts.extensions or { ".ex", ".exs" },
  }

  vim.notify("Analyzing directory: " .. path, vim.log.levels.INFO)
  
  M.execute("analyze_directory", params, function(result)
    debug_log("analyze_directory result: " .. vim.inspect(result))
    
    if result and result.result then
      -- The MCP response wraps the actual result in result.content[1].text (JSON string)
      local actual_result = result.result
      
      -- If it's wrapped in content array, extract it
      if actual_result.content and actual_result.content[1] and actual_result.content[1].text then
        local ok, parsed = pcall(vim.fn.json_decode, actual_result.content[1].text)
        if ok then
          actual_result = parsed
        end
      end
      
      local count = actual_result.analyzed or actual_result.success or 0
      local total = actual_result.total or 0
      vim.notify(string.format("Analyzed %d/%d files", count, total), vim.log.levels.INFO)
    else
      vim.notify("Failed to analyze directory", vim.log.levels.ERROR)
    end
  end)
end

-- Find callers of function under cursor
function M.find_callers()
  local module = M.get_current_module()
  if not module then
    vim.notify("Could not determine current module", vim.log.levels.WARN)
    return
  end

  local func = vim.fn.expand("<cword>")
  local arity = M.get_function_arity()

  local query = string.format("calls %s.%s/%d", module, func, arity)
  
  return M.execute("query_graph", { query = query })
end

-- Refactor: rename function
function M.rename_function(new_name, scope)
  local module = M.get_current_module()
  if not module then
    vim.notify("Could not determine current module", vim.log.levels.WARN)
    return
  end

  local old_name = vim.fn.expand("<cword>")
  local arity = M.get_function_arity()

  local params = {
    operation = "rename_function",
    params = {
      module = module,
      old_name = old_name,
      new_name = new_name,
      arity = arity,
    },
    scope = scope or "project",
    validate = true,
    format = true,
  }

  vim.notify(
    string.format("Renaming %s.%s/%d -> %s", module, old_name, arity, new_name),
    vim.log.levels.INFO
  )

  M.execute("refactor_code", params, function(result)
    if not result or not result.result then
      vim.notify("Refactoring failed: no response", vim.log.levels.ERROR)
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

    if data.success then
      vim.cmd("checktime") -- Reload buffers
      vim.notify("Function renamed successfully", vim.log.levels.INFO)
    else
      local err = data.error or result.error or "unknown error"
      vim.notify("Refactoring failed: " .. vim.inspect(err), vim.log.levels.ERROR)
    end
  end)
end

-- Refactor: rename module
function M.rename_module(old_name, new_name)
  local params = {
    operation = "rename_module",
    params = {
      old_name = old_name,
      new_name = new_name,
    },
    validate = true,
    format = true,
  }

  vim.notify(string.format("Renaming module %s -> %s", old_name, new_name), vim.log.levels.INFO)

  M.execute("refactor_code", params, function(result)
    if not result or not result.result then
      vim.notify("Refactoring failed: no response", vim.log.levels.ERROR)
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

    if data.success then
      vim.cmd("checktime") -- Reload buffers
      vim.notify("Module renamed successfully", vim.log.levels.INFO)
    else
      local err = data.error or result.error or "unknown error"
      vim.notify("Refactoring failed: " .. vim.inspect(err), vim.log.levels.ERROR)
    end
  end)
end

-- Watch current directory
function M.watch_directory(path, extensions)
  path = path or vim.fn.getcwd()
  extensions = extensions or { ".ex", ".exs" }

  local params = {
    path = path,
    extensions = extensions,
  }

  M.execute("watch_directory", params, function(result)
    if result and result.result then
      vim.notify("Watching directory: " .. path, vim.log.levels.INFO)
    else
      vim.notify("Failed to watch directory", vim.log.levels.ERROR)
    end
  end)
end

-- Get graph statistics
function M.graph_stats()
  return M.execute("graph_stats", {})
end

-- Helper: Get current module name
function M.get_current_module()
  local lines = vim.api.nvim_buf_get_lines(0, 0, 100, false)
  for _, line in ipairs(lines) do
    local module = line:match("defmodule%s+([%w%.]+)")
    if module then
      return module
    end
  end
  return nil
end

-- Helper: Get function arity (simplified)
function M.get_function_arity()
  local line = vim.fn.getline(".")
  
  -- Try to match function definition
  local args = line:match("def%s+%w+%((.-)%)")
  if not args then
    args = line:match("defp%s+%w+%((.-)%)")
  end
  
  if not args or args == "" then
    return 0
  end
  
  -- Count commas + 1 for number of arguments
  local _, count = args:gsub(",", "")
  return count + 1
end

-- Helper: Show results in floating window
function M.show_in_float(title, lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

  local width = math.min(100, vim.o.columns - 4)
  local height = math.min(30, vim.o.lines - 4)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  })

  -- Keybindings to close
  local opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set("n", "q", "<cmd>close<cr>", opts)
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", opts)
  
  return buf, win
end

-- Show callers in floating window
function M.show_callers()
  local module = M.get_current_module()
  if not module then
    vim.notify("Could not determine current module", vim.log.levels.WARN)
    return
  end

  local func = vim.fn.expand("<cword>")
  local arity = M.get_function_arity()

  local query = string.format("calls %s.%s/%d", module, func, arity)
  
  M.execute("query_graph", { query = query }, function(result)
    if not result or not result.result then
      vim.notify("No callers found", vim.log.levels.WARN)
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

    if not data.nodes then
      vim.notify("No callers found", vim.log.levels.WARN)
      return
    end

    local lines = { string.format("# Callers of %s.%s/%d", module, func, arity), "" }
    
    for _, node in ipairs(data.nodes) do
      if node.file and node.line then
        table.insert(lines, string.format("- %s:%d", node.file, node.line))
      end
    end

    if #lines == 2 then
      table.insert(lines, "No callers found")
    end

    M.show_in_float("Ragex Callers", lines)
  end)
end

-- Toggle auto-analysis
function M.toggle_auto_analyze()
  M.config.auto_analyze = not M.config.auto_analyze
  
  if M.config.auto_analyze then
    local ragex_group = vim.api.nvim_create_augroup("RagexAnalysis", { clear = true })
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = ragex_group,
      pattern = { "*.ex", "*.exs" },
      callback = function()
        M.analyze_current_file()
      end,
    })
    vim.notify("Ragex auto-analysis enabled", vim.log.levels.INFO)
  else
    vim.api.nvim_del_augroup_by_name("RagexAnalysis")
    vim.notify("Ragex auto-analysis disabled", vim.log.levels.INFO)
  end
end

-- Setup function
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  
  -- Auto-analyze on save for Elixir files (if enabled)
  if M.config.auto_analyze then
    local ragex_group = vim.api.nvim_create_augroup("RagexAnalysis", { clear = true })
    
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = ragex_group,
      pattern = { "*.ex", "*.exs" },
      callback = function()
        M.analyze_current_file()
      end,
    })
    debug_log("Auto-analysis enabled")
  end
  
  debug_log("Ragex integration loaded")
end

return M

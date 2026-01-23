-- Utility functions for ragex.nvim

local M = {}

-- Get current module name from buffer
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

-- Get function name and arity under cursor
function M.get_function_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  
  -- Try to find function definition
  local func, arity = line:match("def%s+([%w_]+)%((.-)%)")
  if func then
    local param_count = 0
    if arity and arity ~= "" then
      param_count = select(2, arity:gsub(",", "")) + 1
    end
    return func, param_count
  end
  
  -- Try to find function call
  func, arity = line:match("([%w_]+)%((.-)%)")
  if func then
    local param_count = 0
    if arity and arity ~= "" then
      param_count = select(2, arity:gsub(",", "")) + 1
    end
    return func, param_count
  end
  
  -- Just get word under cursor
  local word = vim.fn.expand("<cword>")
  return word, nil
end

-- Get word under cursor
function M.get_word_under_cursor()
  return vim.fn.expand("<cword>")
end

-- Get visual selection
function M.get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  local start_line = start_pos[2]
  local end_line = end_pos[2]
  
  if start_line == 0 or end_line == 0 then
    return nil
  end
  
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  return table.concat(lines, "\n")
end

-- Get visual selection range
function M.get_visual_range()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  return start_pos[2], end_pos[2]
end

-- Parse MCP response
function M.parse_mcp_response(response)
  if not response then
    return nil, "Empty response"
  end
  
  -- Handle error responses
  if response.error then
    return nil, response.error.message or "Unknown error"
  end
  
  -- Extract result
  if not response.result then
    return nil, "No result in response"
  end
  
  local result = response.result
  
  -- Unwrap MCP content structure
  if result.content and result.content[1] and result.content[1].text then
    local ok, parsed = pcall(vim.json.decode, result.content[1].text)
    if ok then
      return parsed, nil
    end
  end
  
  return result, nil
end

-- Format duration in human-readable form
function M.format_duration(ms)
  if ms < 1000 then
    return string.format("%dms", ms)
  elseif ms < 60000 then
    return string.format("%.1fs", ms / 1000)
  else
    return string.format("%.1fm", ms / 60000)
  end
end

-- Truncate string with ellipsis
function M.truncate(str, max_len)
  if #str <= max_len then
    return str
  end
  return str:sub(1, max_len - 3) .. "..."
end

-- Deep copy table
function M.deep_copy(obj)
  if type(obj) ~= "table" then
    return obj
  end
  
  local copy = {}
  for k, v in pairs(obj) do
    copy[M.deep_copy(k)] = M.deep_copy(v)
  end
  
  return setmetatable(copy, getmetatable(obj))
end

-- Check if file is an Elixir file
function M.is_elixir_file(filepath)
  return filepath:match("%.exs?$") ~= nil
end

-- Check if file is an Erlang file
function M.is_erlang_file(filepath)
  return filepath:match("%.[eh]rl$") ~= nil
end

-- Check if file is a Python file
function M.is_python_file(filepath)
  return filepath:match("%.py$") ~= nil
end

-- Check if file is a JavaScript/TypeScript file
function M.is_javascript_file(filepath)
  return filepath:match("%.[jt]sx?$") ~= nil or filepath:match("%.mjs$") ~= nil
end

-- Get file extension
function M.get_extension(filepath)
  return filepath:match("%.([^%.]+)$")
end

-- Validate module name
function M.is_valid_module_name(name)
  return name:match("^[A-Z][%w%.]*$") ~= nil
end

-- Validate function name
function M.is_valid_function_name(name)
  return name:match("^[a-z_][%w_]*[!?]?$") ~= nil
end

-- Parse node_id string (e.g., "Elixir.Module.function/2")
function M.parse_node_id(node_id)
  if not node_id then
    return nil, nil, nil
  end
  
  -- Try module.function/arity format
  local module, func, arity = node_id:match("^(.+)%.([^%.]+)/(%d+)$")
  if module and func and arity then
    return module, func, tonumber(arity)
  end
  
  -- Try just module
  if node_id:match("^[A-Z]") then
    return node_id, nil, nil
  end
  
  return nil, nil, nil
end

-- Format node_id for display
function M.format_node_id(module, func, arity)
  if not module then
    return "unknown"
  end
  
  if not func then
    return module
  end
  
  if arity then
    return string.format("%s.%s/%d", module, func, arity)
  else
    return string.format("%s.%s", module, func)
  end
end

-- Escape special characters for shell
function M.shell_escape(str)
  return vim.fn.shellescape(str)
end

-- Read file contents
function M.read_file(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return nil, "Cannot open file"
  end
  
  local content = file:read("*a")
  file:close()
  
  return content, nil
end

-- Write file contents
function M.write_file(filepath, content)
  local file = io.open(filepath, "w")
  if not file then
    return false, "Cannot write file"
  end
  
  file:write(content)
  file:close()
  
  return true, nil
end

-- Get project root (look for mix.exs, .git, etc.)
function M.get_project_root(start_path)
  start_path = start_path or vim.fn.getcwd()
  
  local markers = { "mix.exs", "rebar.config", ".git", "package.json" }
  
  local function find_root(path)
    for _, marker in ipairs(markers) do
      local marker_path = path .. "/" .. marker
      if vim.fn.filereadable(marker_path) == 1 or vim.fn.isdirectory(marker_path) == 1 then
        return path
      end
    end
    
    local parent = vim.fn.fnamemodify(path, ":h")
    if parent == path then
      return nil
    end
    
    return find_root(parent)
  end
  
  return find_root(start_path) or start_path
end

-- Debounce function
function M.debounce(func, delay)
  local timer = nil
  
  return function(...)
    local args = {...}
    
    if timer then
      vim.fn.timer_stop(timer)
    end
    
    timer = vim.fn.timer_start(delay, function()
      func(unpack(args))
      timer = nil
    end)
  end
end

-- Throttle function
function M.throttle(func, delay)
  local last_run = 0
  
  return function(...)
    local now = vim.loop.now()
    if now - last_run >= delay then
      last_run = now
      func(...)
    end
  end
end

return M

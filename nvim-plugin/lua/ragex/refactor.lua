-- Refactoring operations for ragex.nvim

local M = {}
local core = require("ragex.core")
local utils = require("ragex.utils")
local ui = require("ragex.ui")

-- Rename function
function M.rename_function(old_name, new_name, arity, opts)
  opts = opts or {}
  
  -- Try to get context from cursor if not provided
  local module = opts.module or utils.get_current_module()
  if not module then
    ui.notify("Could not determine current module", "warn")
    return
  end
  
  if not old_name then
    old_name, arity = utils.get_function_under_cursor()
  end
  
  if not old_name then
    ui.notify("Could not determine function name", "warn")
    return
  end
  
  -- Prompt for new name if not provided
  if not new_name then
    ui.input("New function name: ", {
      default = old_name,
      validate = function(input)
        if not utils.is_valid_function_name(input) then
          return false, "Invalid function name"
        end
        return true
      end,
    }, function(input)
      if input then
        M.rename_function(old_name, input, arity, opts)
      end
    end)
    return
  end
  
  local params = {
    operation = "rename_function",
    module = module,
    old_name = old_name,
    new_name = new_name,
    scope = opts.scope or "project",
    validate = true,
    format = true,
  }
  
  if arity then
    params.arity = arity
  end
  
  local loading = ui.notify_loading(string.format("Renaming %s to %s...", old_name, new_name))
  
  core.execute("refactor_code", params, function(result, error_type)
    ui.dismiss_notification(loading)
    
    if error_type then
      ui.notify("Refactoring failed: " .. error_type, "error")
      return
    end
    
    local data, err = utils.parse_mcp_response(result)
    if err then
      ui.notify("Refactoring failed: " .. err, "error")
      return
    end
    
    if data.success then
      ui.notify(string.format("Renamed %s to %s (%d files)", old_name, new_name, data.files_edited or 0), "info")
    else
      ui.notify("Refactoring failed: " .. (data.error or "Unknown error"), "error")
    end
  end)
end

-- Rename module
function M.rename_module(old_name, new_name)
  if not old_name then
    old_name = utils.get_current_module()
  end
  
  if not old_name then
    ui.notify("Could not determine current module", "warn")
    return
  end
  
  if not new_name then
    ui.input("New module name: ", {
      default = old_name,
      validate = function(input)
        if not utils.is_valid_module_name(input) then
          return false, "Invalid module name"
        end
        return true
      end,
    }, function(input)
      if input then
        M.rename_module(old_name, input)
      end
    end)
    return
  end
  
  local params = {
    operation = "rename_module",
    old_name = old_name,
    new_name = new_name,
    validate = true,
    format = true,
  }
  
  local loading = ui.notify_loading(string.format("Renaming module %s to %s...", old_name, new_name))
  
  core.execute("refactor_code", params, function(result, error_type)
    ui.dismiss_notification(loading)
    
    if error_type then
      ui.notify("Refactoring failed: " .. error_type, "error")
      return
    end
    
    local data, err = utils.parse_mcp_response(result)
    if err then
      ui.notify("Refactoring failed: " .. err, "error")
      return
    end
    
    if data.success then
      ui.notify(string.format("Renamed module %s to %s (%d files)", old_name, new_name, data.files_edited or 0), "info")
    else
      ui.notify("Refactoring failed: " .. (data.error or "Unknown error"), "error")
    end
  end)
end

-- Extract function (from visual selection)
function M.extract_function(new_func_name, opts)
  opts = opts or {}
  
  local module = opts.module or utils.get_current_module()
  if not module then
    ui.notify("Could not determine current module", "warn")
    return
  end
  
  local start_line, end_line = utils.get_visual_range()
  if not start_line or not end_line then
    ui.notify("No visual selection", "warn")
    return
  end
  
  if not new_func_name then
    ui.input("New function name: ", {
      validate = function(input)
        if not utils.is_valid_function_name(input) then
          return false, "Invalid function name"
        end
        return true
      end,
    }, function(input)
      if input then
        M.extract_function(input, opts)
      end
    end)
    return
  end
  
  local params = {
    operation = "extract_function",
    module = module,
    new_function = new_func_name,
    line_start = start_line,
    line_end = end_line,
    validate = true,
    format = true,
  }
  
  local loading = ui.notify_loading("Extracting function...")
  
  core.execute("advanced_refactor", params, function(result, error_type)
    ui.dismiss_notification(loading)
    
    if error_type then
      ui.notify("Refactoring failed: " .. error_type, "error")
      return
    end
    
    local data, err = utils.parse_mcp_response(result)
    if err then
      ui.notify("Refactoring failed: " .. err, "error")
      return
    end
    
    if data.success then
      ui.notify(string.format("Extracted function %s", new_func_name), "info")
    else
      ui.notify("Refactoring failed: " .. (data.error or "Unknown error"), "error")
    end
  end)
end

-- Inline function
function M.inline_function(module, func_name, arity)
  if not module then
    module = utils.get_current_module()
  end
  
  if not module then
    ui.notify("Could not determine current module", "warn")
    return
  end
  
  if not func_name then
    func_name, arity = utils.get_function_under_cursor()
  end
  
  if not func_name then
    ui.notify("Could not determine function name", "warn")
    return
  end
  
  -- Confirm before inlining
  ui.confirm(string.format("Inline function %s.%s/%s?", module, func_name, arity or "?"), function(confirmed)
    if not confirmed then
      return
    end
    
    local params = {
      operation = "inline_function",
      module = module,
      function_name = func_name,
      validate = true,
      format = true,
    }
    
    if arity then
      params.arity = arity
    end
    
    local loading = ui.notify_loading("Inlining function...")
    
    core.execute("advanced_refactor", params, function(result, error_type)
      ui.dismiss_notification(loading)
      
      if error_type then
        ui.notify("Refactoring failed: " .. error_type, "error")
        return
      end
      
      local data, err = utils.parse_mcp_response(result)
      if err then
        ui.notify("Refactoring failed: " .. err, "error")
        return
      end
      
      if data.success then
        ui.notify(string.format("Inlined function %s", func_name), "info")
      else
        ui.notify("Refactoring failed: " .. (data.error or "Unknown error"), "error")
      end
    end)
  end)
end

-- Convert visibility (def <-> defp)
function M.convert_visibility(module, func_name, arity, to_visibility)
  if not module then
    module = utils.get_current_module()
  end
  
  if not module then
    ui.notify("Could not determine current module", "warn")
    return
  end
  
  if not func_name then
    func_name, arity = utils.get_function_under_cursor()
  end
  
  if not func_name then
    ui.notify("Could not determine function name", "warn")
    return
  end
  
  if not to_visibility then
    ui.select({"public", "private"}, {
      prompt = "Convert to:",
    }, function(choice)
      if choice then
        M.convert_visibility(module, func_name, arity, choice)
      end
    end)
    return
  end
  
  local params = {
    operation = "convert_visibility",
    module = module,
    function_name = func_name,
    to_visibility = to_visibility,
    validate = true,
    format = true,
  }
  
  if arity then
    params.arity = arity
  end
  
  local loading = ui.notify_loading("Converting visibility...")
  
  core.execute("advanced_refactor", params, function(result, error_type)
    ui.dismiss_notification(loading)
    
    if error_type then
      ui.notify("Refactoring failed: " .. error_type, "error")
      return
    end
    
    local data, err = utils.parse_mcp_response(result)
    if err then
      ui.notify("Refactoring failed: " .. err, "error")
      return
    end
    
    if data.success then
      ui.notify(string.format("Converted %s to %s", func_name, to_visibility), "info")
    else
      ui.notify("Refactoring failed: " .. (data.error or "Unknown error"), "error")
    end
  end)
end

return M

-- Code analysis and quality features for ragex.nvim

local M = {}
local core = require("ragex.core")
local utils = require("ragex.utils")
local ui = require("ragex.ui")

-- Helper to execute analysis and show results
local function execute_analysis(method, params, title, formatter)
  local loading = ui.notify_loading("Analyzing...")
  
  core.execute(method, params or {}, function(result, error_type)
    ui.dismiss_notification(loading)
    
    if error_type then
      ui.notify("Analysis failed: " .. error_type, "error")
      return
    end
    
    local data, err = utils.parse_mcp_response(result)
    if err then
      ui.notify("Analysis failed: " .. err, "error")
      return
    end
    
    if formatter then
      ui.show_results(data, { title = title, formatter = formatter })
    else
      ui.show_float({vim.inspect(data)}, { title = title })
    end
  end)
end

-- Find duplicates
function M.find_duplicates(opts)
  opts = opts or {}
  execute_analysis("find_duplicates", opts, "Code Duplicates")
end

-- Find similar code
function M.find_similar_code(code_snippet, opts)
  opts = opts or {}
  opts.code = code_snippet or utils.get_visual_selection()
  
  if not opts.code then
    ui.notify("No code provided", "warn")
    return
  end
  
  execute_analysis("find_similar_code", opts, "Similar Code")
end

-- Find dead code
function M.find_dead_code(opts)
  opts = opts or {}
  execute_analysis("find_dead_code", opts, "Dead Code")
end

-- Analyze dependencies
function M.analyze_dependencies(opts)
  opts = opts or {}
  execute_analysis("analyze_dependencies", opts, "Dependencies")
end

-- Coupling report
function M.coupling_report()
  execute_analysis("coupling_report", {}, "Coupling Report")
end

-- Quality report
function M.quality_report()
  execute_analysis("quality_report", {}, "Quality Report")
end

-- Analyze impact
function M.analyze_impact(module, func_name, arity)
  module = module or utils.get_current_module()
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
  
  local params = {
    module = module,
    function_name = func_name,
  }
  if arity then
    params.arity = arity
  end
  
  execute_analysis("analyze_impact", params, string.format("Impact: %s.%s", module, func_name))
end

-- Estimate refactoring effort
function M.estimate_effort(module, func_name, arity)
  module = module or utils.get_current_module()
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
  
  local params = {
    module = module,
    function_name = func_name,
  }
  if arity then
    params.arity = arity
  end
  
  execute_analysis("estimate_refactoring_effort", params, "Refactoring Effort")
end

-- Risk assessment
function M.risk_assessment(module, func_name, arity)
  module = module or utils.get_current_module()
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
  
  local params = {
    module = module,
    function_name = func_name,
  }
  if arity then
    params.arity = arity
  end
  
  execute_analysis("risk_assessment", params, "Risk Assessment")
end

return M

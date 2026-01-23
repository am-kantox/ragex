-- Vim command definitions for ragex.nvim

local M = {}

function M.setup()
  -- Main Ragex command with subcommands
  vim.api.nvim_create_user_command("Ragex", function(opts)
    local ragex = require("ragex")
    local args = opts.fargs
    local subcmd = args[1]
    
    if not subcmd then
      vim.notify("[Ragex] Usage: :Ragex <subcommand>", vim.log.levels.INFO)
      vim.notify("Try :Ragex search, :Ragex analyze_file, etc.", vim.log.levels.INFO)
      return
    end
    
    -- Search commands
    if subcmd == "search" then
      ragex.telescope.search()
    elseif subcmd == "search_word" then
      ragex.telescope.search_word()
    elseif subcmd == "functions" then
      ragex.telescope.functions()
    elseif subcmd == "modules" then
      ragex.telescope.modules()
    
    -- Analysis commands
    elseif subcmd == "analyze_file" then
      ragex.analyze_file()
    elseif subcmd == "analyze_directory" then
      ragex.analyze_directory()
    elseif subcmd == "watch_directory" then
      ragex.watch_directory()
    elseif subcmd == "graph_stats" then
      ragex.graph_stats()
    elseif subcmd == "toggle_auto" then
      ragex.toggle_auto_analyze()
    
    -- Navigation commands
    elseif subcmd == "find_callers" then
      ragex.telescope.callers()
    elseif subcmd == "find_paths" then
      vim.notify("[Ragex] find_paths requires parameters", vim.log.levels.WARN)
    
    -- Refactoring commands
    elseif subcmd == "rename_function" then
      ragex.refactor.rename_function()
    elseif subcmd == "rename_module" then
      ragex.refactor.rename_module()
    elseif subcmd == "extract_function" then
      ragex.refactor.extract_function()
    elseif subcmd == "inline_function" then
      ragex.refactor.inline_function()
    elseif subcmd == "convert_visibility" then
      ragex.refactor.convert_visibility()
    
    -- Code quality commands
    elseif subcmd == "find_duplicates" then
      ragex.telescope.duplicates()
    elseif subcmd == "find_similar" then
      ragex.analysis.find_similar_code()
    elseif subcmd == "find_dead_code" then
      ragex.telescope.dead_code()
    elseif subcmd == "analyze_dependencies" then
      ragex.analysis.analyze_dependencies()
    elseif subcmd == "coupling_report" then
      ragex.analysis.coupling_report()
    elseif subcmd == "quality_report" then
      ragex.analysis.quality_report()
    
    -- Impact analysis commands
    elseif subcmd == "analyze_impact" then
      ragex.analysis.analyze_impact()
    elseif subcmd == "estimate_effort" then
      ragex.analysis.estimate_effort()
    elseif subcmd == "risk_assessment" then
      ragex.analysis.risk_assessment()
    
    -- Graph algorithm commands
    elseif subcmd == "betweenness_centrality" then
      ragex.graph.betweenness_centrality()
    elseif subcmd == "closeness_centrality" then
      ragex.graph.closeness_centrality()
    elseif subcmd == "detect_communities" then
      ragex.graph.detect_communities()
    elseif subcmd == "export_graph" then
      ragex.graph.export_graph()
    
    else
      vim.notify("[Ragex] Unknown subcommand: " .. subcmd, vim.log.levels.ERROR)
    end
  end, {
    nargs = "+",
    complete = function(arg_lead, cmdline, cursor_pos)
      local subcommands = {
        -- Search
        "search",
        "search_word",
        "functions",
        "modules",
        
        -- Analysis
        "analyze_file",
        "analyze_directory",
        "watch_directory",
        "graph_stats",
        "toggle_auto",
        
        -- Navigation
        "find_callers",
        "find_paths",
        
        -- Refactoring
        "rename_function",
        "rename_module",
        "extract_function",
        "inline_function",
        "convert_visibility",
        
        -- Code quality
        "find_duplicates",
        "find_similar",
        "find_dead_code",
        "analyze_dependencies",
        "coupling_report",
        "quality_report",
        
        -- Impact analysis
        "analyze_impact",
        "estimate_effort",
        "risk_assessment",
        
        -- Graph algorithms
        "betweenness_centrality",
        "closeness_centrality",
        "detect_communities",
        "export_graph",
      }
      
      -- Filter subcommands based on what user has typed
      local matches = {}
      for _, cmd in ipairs(subcommands) do
        if cmd:find("^" .. vim.pesc(arg_lead)) then
          table.insert(matches, cmd)
        end
      end
      
      return matches
    end,
  })
end

return M

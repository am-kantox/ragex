-- Graph algorithms and visualizations for ragex.nvim

local M = {}
local core = require("ragex.core")
local utils = require("ragex.utils")
local ui = require("ragex.ui")

-- Betweenness centrality
function M.betweenness_centrality(opts)
  opts = opts or {}
  
  local loading = ui.notify_loading("Computing betweenness centrality...")
  
  core.execute("betweenness_centrality", opts, function(result, error_type)
    ui.dismiss_notification(loading)
    
    if error_type then
      ui.notify("Failed to compute centrality: " .. error_type, "error")
      return
    end
    
    local data, err = utils.parse_mcp_response(result)
    if err then
      ui.notify("Failed to parse centrality: " .. err, "error")
      return
    end
    
    -- Format and show results
    local lines = {
      "Betweenness Centrality (Top 20)",
      string.rep("=", 60),
      "",
    }
    
    if data.scores then
      for i, node in ipairs(data.scores) do
        if i > 20 then break end
        table.insert(lines, string.format("%2d. %s: %.4f", i, node.id, node.score))
      end
    end
    
    ui.show_float(lines, { title = "Betweenness Centrality" })
  end)
end

-- Closeness centrality
function M.closeness_centrality(opts)
  opts = opts or {}
  
  local loading = ui.notify_loading("Computing closeness centrality...")
  
  core.execute("closeness_centrality", opts, function(result, error_type)
    ui.dismiss_notification(loading)
    
    if error_type then
      ui.notify("Failed to compute centrality: " .. error_type, "error")
      return
    end
    
    local data, err = utils.parse_mcp_response(result)
    if err then
      ui.notify("Failed to parse centrality: " .. err, "error")
      return
    end
    
    -- Format and show results
    local lines = {
      "Closeness Centrality (Top 20)",
      string.rep("=", 60),
      "",
    }
    
    if data.scores then
      for i, node in ipairs(data.scores) do
        if i > 20 then break end
        table.insert(lines, string.format("%2d. %s: %.4f", i, node.id, node.score))
      end
    end
    
    ui.show_float(lines, { title = "Closeness Centrality" })
  end)
end

-- Detect communities
function M.detect_communities(opts)
  opts = opts or {}
  
  local loading = ui.notify_loading("Detecting communities...")
  
  core.execute("detect_communities", opts, function(result, error_type)
    ui.dismiss_notification(loading)
    
    if error_type then
      ui.notify("Failed to detect communities: " .. error_type, "error")
      return
    end
    
    local data, err = utils.parse_mcp_response(result)
    if err then
      ui.notify("Failed to parse communities: " .. err, "error")
      return
    end
    
    -- Format and show results
    local lines = {
      string.format("Communities Detected (%d total)", data.num_communities or 0),
      string.rep("=", 60),
      "",
    }
    
    if data.communities then
      for i, community in ipairs(data.communities) do
        table.insert(lines, string.format("Community %d (%d members):", i, #community.members))
        for j, member in ipairs(community.members) do
          if j > 10 then
            table.insert(lines, string.format("  ... and %d more", #community.members - 10))
            break
          end
          table.insert(lines, string.format("  • %s", member))
        end
        table.insert(lines, "")
      end
    end
    
    ui.show_float(lines, { title = "Communities", height = math.min(#lines + 2, 40) })
  end)
end

-- Export graph
function M.export_graph(opts)
  opts = opts or {}
  
  -- Prompt for format if not provided
  if not opts.format then
    ui.select({"graphviz", "d3"}, {
      prompt = "Export format:",
    }, function(choice)
      if choice then
        opts.format = choice
        M.export_graph(opts)
      end
    end)
    return
  end
  
  -- Prompt for output path if not provided
  if not opts.output then
    local default_ext = opts.format == "graphviz" and ".dot" or ".json"
    ui.input("Output file: ", {
      default = "graph" .. default_ext,
    }, function(input)
      if input then
        opts.output = input
        M.export_graph(opts)
      end
    end)
    return
  end
  
  local loading = ui.notify_loading("Exporting graph...")
  
  core.execute("export_graph", opts, function(result, error_type)
    ui.dismiss_notification(loading)
    
    if error_type then
      ui.notify("Failed to export graph: " .. error_type, "error")
      return
    end
    
    local data, err = utils.parse_mcp_response(result)
    if err then
      ui.notify("Failed to parse export: " .. err, "error")
      return
    end
    
    if data.success then
      ui.notify(string.format("Graph exported to %s", opts.output), "info")
    else
      ui.notify("Export failed: " .. (data.error or "Unknown error"), "error")
    end
  end)
end

return M

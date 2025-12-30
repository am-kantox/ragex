#!/usr/bin/env elixir

# Test MCP protocol without stdio
Mix.install([{:ragex, path: "."}], consolidate_protocols: false)

require Logger
Logger.configure(level: :info)

alias Ragex.MCP.{Protocol, Handlers.Tools}

IO.puts("\n=== Testing MCP Protocol ===\n")

# Test 1: Initialize
IO.puts("1. Testing initialize...")
init_msg = %{
  "jsonrpc" => "2.0",
  "id" => 1,
  "method" => "initialize",
  "params" => %{
    "protocolVersion" => "2024-11-05",
    "clientInfo" => %{"name" => "test", "version" => "1.0"}
  }
}

init_response = %{
  jsonrpc: "2.0",
  result: %{
    protocolVersion: "2024-11-05",
    serverInfo: %{name: "ragex", version: "0.2.0"},
    capabilities: %{tools: %{}}
  },
  id: 1
}

case Protocol.encode(init_response) do
  {:ok, json} ->
    IO.puts("   ✓ Initialize response encodes OK")
    IO.puts("   JSON: #{json}")
    
  {:error, reason} ->
    IO.puts("   ✗ Initialize response encoding FAILED: #{inspect(reason)}")
end

# Test 2: Tools list
IO.puts("\n2. Testing tools/list...")
tools_result = Tools.list_tools()
tools_response = Protocol.success_response(tools_result, 2)

case Protocol.encode(tools_response) do
  {:ok, json} ->
    IO.puts("   ✓ Tools list response encodes OK")
    decoded = Jason.decode!(json)
    tool_count = length(decoded["result"]["tools"] || [])
    IO.puts("   Found #{tool_count} tools")
    
  {:error, reason} ->
    IO.puts("   ✗ Tools list response encoding FAILED: #{inspect(reason)}")
end

# Test 3: Tool call
IO.puts("\n3. Testing tools/call...")
case Tools.call_tool("graph_stats", %{}) do
  {:ok, result} ->
    formatted = %{
      content: [
        %{type: "text", text: Jason.encode!(result)}
      ]
    }
    call_response = Protocol.success_response(formatted, 3)
    
    case Protocol.encode(call_response) do
      {:ok, json} ->
        IO.puts("   ✓ Tool call response encodes OK")
        
      {:error, reason} ->
        IO.puts("   ✗ Tool call response encoding FAILED: #{inspect(reason)}")
    end
    
  {:error, reason} ->
    IO.puts("   ✗ Tool call FAILED: #{inspect(reason)}")
end

IO.puts("\n=== Tests Complete ===\n")

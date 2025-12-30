#!/usr/bin/env elixir

# Debug script to test MCP server with verbose logging
# Usage: mix run debug_mcp.exs

require Logger

Logger.configure(level: :debug)

# Start the application
{:ok, _} = Application.ensure_all_started(:ragex)

Logger.info("=== MCP Debug Mode ===")
Logger.info("Server started. Waiting for stdin...")
Logger.info("You can test by sending JSON-RPC messages")

# Example test message you can paste:
test_init = %{
  "jsonrpc" => "2.0",
  "id" => 1,
  "method" => "initialize",
  "params" => %{
    "protocolVersion" => "2024-11-05",
    "clientInfo" => %{
      "name" => "test-client",
      "version" => "1.0.0"
    }
  }
}

Logger.info("Example initialize message:")
Logger.info(Jason.encode!(test_init, pretty: true))

# Keep running
Process.sleep(:infinity)

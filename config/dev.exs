import Config

# Disable stdio-based MCP server in development (iex sessions)
# The SocketServer will still work for MCP clients

start_server? = !System.get_env("RAGEX_NO_SERVER")
config :ragex, :start_server, start_server?

# You can enable verbose logging in development
config :logger, level: :debug

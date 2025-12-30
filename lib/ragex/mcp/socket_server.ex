defmodule Ragex.MCP.SocketServer do
  @moduledoc """
  Unix socket server for MCP protocol.
  
  Allows multiple clients to connect to a persistent server instance.
  Each connection handles requests independently.
  """
  
  use GenServer
  require Logger
  
  alias Ragex.MCP.{Protocol, Handlers.Tools}
  
  @socket_path "/tmp/ragex_mcp.sock"
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(_opts) do
    # Remove existing socket file
    File.rm(@socket_path)
    
    # Create Unix socket
    case :gen_tcp.listen(0, [:binary, {:packet, :line}, {:active, false}, {:ifaddr, {:local, @socket_path}}]) do
      {:ok, socket} ->
        Logger.info("MCP Socket Server listening on #{@socket_path}")
        spawn_link(fn -> accept_loop(socket) end)
        {:ok, %{socket: socket}}
        
      {:error, reason} ->
        Logger.error("Failed to create socket: #{inspect(reason)}")
        {:stop, reason}
    end
  end
  
  defp accept_loop(listen_socket) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, client_socket} ->
        Logger.debug("Client connected")
        spawn(fn -> handle_client(client_socket) end)
        accept_loop(listen_socket)
        
      {:error, reason} ->
        Logger.error("Accept failed: #{inspect(reason)}")
    end
  end
  
  defp handle_client(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, line} ->
        line = String.trim(line)
        
        case Protocol.decode(line) do
          {:ok, message} ->
            response = process_message(message)
            
            case Protocol.encode(response) do
              {:ok, json} ->
                :gen_tcp.send(socket, json <> "\n")
                
              {:error, reason} ->
                Logger.error("Failed to encode response: #{inspect(reason)}")
            end
            
          {:error, reason} ->
            Logger.error("Failed to decode message: #{inspect(reason)}")
            error = Protocol.parse_error(nil)
            
            case Protocol.encode(error) do
              {:ok, json} -> :gen_tcp.send(socket, json <> "\n")
              _ -> :ok
            end
        end
        
        # Handle another request on the same connection
        handle_client(socket)
        
      {:error, :closed} ->
        Logger.debug("Client disconnected")
        :gen_tcp.close(socket)
        
      {:error, reason} ->
        Logger.error("Recv failed: #{inspect(reason)}")
        :gen_tcp.close(socket)
    end
  end
  
  defp process_message(%{"method" => method} = message) do
    id = Map.get(message, "id")
    params = Map.get(message, "params", %{})
    
    case method do
      "initialize" ->
        handle_initialize(params, id)
        
      "tools/list" ->
        handle_tools_list(id)
        
      "tools/call" ->
        handle_tools_call(params, id)
        
      "ping" ->
        Protocol.success_response(%{}, id)
        
      _ ->
        Protocol.method_not_found(method, id)
    end
  end
  
  defp process_message(_message) do
    Protocol.invalid_request(nil)
  end
  
  defp handle_initialize(params, id) do
    result = %{
      protocolVersion: "2024-11-05",
      serverInfo: %{
        name: "ragex",
        version: "0.2.0"
      },
      capabilities: %{
        tools: %{}
      }
    }
    
    Protocol.success_response(result, id)
  end
  
  defp handle_tools_list(id) do
    result = Tools.list_tools()
    Protocol.success_response(result, id)
  end
  
  defp handle_tools_call(params, id) do
    tool_name = Map.get(params, "name")
    arguments = Map.get(params, "arguments", %{})
    
    case Tools.call_tool(tool_name, arguments) do
      {:ok, result} ->
        formatted = %{
          content: [
            %{
              type: "text",
              text: Jason.encode!(result)
            }
          ]
        }
        Protocol.success_response(formatted, id)
        
      {:error, reason} ->
        Protocol.internal_error(inspect(reason), id)
    end
  end
end

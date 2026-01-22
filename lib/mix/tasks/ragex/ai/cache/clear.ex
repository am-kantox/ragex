defmodule Mix.Tasks.Ragex.Ai.Cache.Clear do
  @moduledoc """
  Clear AI response cache.

  ## Usage

      # Clear all cache
      mix ragex.ai.cache.clear
      
      # Clear specific operation
      mix ragex.ai.cache.clear --operation query
      mix ragex.ai.cache.clear --operation explain

  Removes cached AI responses. Useful after configuration changes or for testing.
  """

  use Mix.Task
  require Logger
  alias Ragex.AI.Cache

  @shortdoc "Clear AI cache"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _} = OptionParser.parse!(args, strict: [operation: :string])

    case Keyword.get(opts, :operation) do
      nil ->
        :ok = Cache.clear()
        IO.puts("AI cache cleared successfully")

      operation_str ->
        operation = String.to_atom(operation_str)
        :ok = Cache.clear(operation)
        IO.puts("AI cache cleared for operation: #{operation}")
    end
  end
end

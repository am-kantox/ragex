defmodule Mix.Tasks.Ragex.Ai.Cache.Stats do
  @moduledoc """
  Display AI response cache statistics.

  ## Usage

      mix ragex.ai.cache.stats

  Shows cache hit rates, size, and usage by operation.
  """

  use Mix.Task
  require Logger

  @shortdoc "Display AI cache statistics"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    stats = Ragex.AI.Cache.stats()

    IO.puts("\n=== AI Cache Statistics ===\n")
    IO.puts("Enabled: #{stats.enabled}")
    IO.puts("Total entries: #{stats.size}")
    IO.puts("Max size: #{stats.max_size}")
    IO.puts("Default TTL: #{stats.ttl}s")

    IO.puts("\n--- Overall Performance ---")
    IO.puts("Hits: #{stats.hits}")
    IO.puts("Misses: #{stats.misses}")
    IO.puts("Puts: #{stats.puts}")
    IO.puts("Evictions: #{stats.evictions}")
    IO.puts("Hit rate: #{Float.round(stats.hit_rate * 100, 2)}%")

    if map_size(stats.by_operation) > 0 do
      IO.puts("\n--- By Operation ---")

      Enum.each(stats.by_operation, fn {operation, op_stats} ->
        IO.puts("\n#{operation}:")
        IO.puts("  Entries: #{op_stats.size}")
        IO.puts("  TTL: #{op_stats.ttl}s")
        IO.puts("  Max size: #{op_stats.max_size}")
        IO.puts("  Hits: #{op_stats.hits}")
        IO.puts("  Misses: #{op_stats.misses}")
        IO.puts("  Hit rate: #{Float.round(op_stats.hit_rate * 100, 2)}%")
      end)
    end

    IO.puts("\n")
  end
end

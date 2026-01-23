defmodule Mix.Tasks.Ragex.Cache.Clear do
  @moduledoc """
  Clears cached embeddings.

  ## Usage

      mix ragex.cache.clear [options]

  ## Options

      --current             Clear cache for the current project only
      --all                 Clear all cached projects
      --older-than DAYS     Clear caches older than N days
      --force               Skip confirmation prompt

  ## Examples

      # Clear current project cache (with confirmation)
      $ mix ragex.cache.clear --current

      # Clear all caches without confirmation
      $ mix ragex.cache.clear --all --force

      # Clear caches older than 30 days
      $ mix ragex.cache.clear --older-than 30

  """

  use Mix.Task

  alias Ragex.CLI.{Colors, Output, Progress, Prompt}
  alias Ragex.Embeddings.Persistence

  @shortdoc "Clear embedding caches"

  @impl Mix.Task
  def run(args) do
    {opts, _} =
      OptionParser.parse!(args,
        strict: [current: :boolean, all: :boolean, older_than: :integer, force: :boolean]
      )

    cond do
      opts[:current] ->
        clear_current(opts[:force])

      opts[:all] ->
        clear_all(opts[:force])

      opts[:older_than] ->
        clear_older_than(opts[:older_than], opts[:force])

      true ->
        IO.puts(Colors.error("Error: Please specify --current, --all, or --older-than"))

        IO.puts(
          Colors.muted(
            "\nUsage: mix ragex.cache.clear [--current | --all | --older-than DAYS] [--force]"
          )
        )

        IO.puts(Colors.muted("Run `mix help ragex.cache.clear` for more information."))
    end
  end

  defp clear_current(force) do
    Output.section("Clear Current Project Cache")

    case Persistence.stats() do
      {:ok, stats} ->
        if force or confirm_clear(stats) do
          spinner = Progress.spinner(label: "Clearing cache...")
          :ok = Persistence.clear(:current)
          Progress.stop_spinner(spinner, Colors.success("✓ Cache cleared successfully"))
          IO.puts("")
        else
          IO.puts(Colors.muted("Cancelled."))
          IO.puts("")
        end

      {:error, :not_found} ->
        IO.puts(Colors.warning("No cache found for current project."))
        IO.puts("")

      {:error, reason} ->
        IO.puts(Colors.error("Error: #{inspect(reason)}"))
        IO.puts("")
    end
  end

  defp clear_all(force) do
    Output.section("Clear All Ragex Caches")

    cache_root = Path.join(System.user_home!(), ".cache/ragex")

    if File.exists?(cache_root) do
      cache_dirs = File.ls!(cache_root)
      count = length(cache_dirs)

      if count == 0 do
        IO.puts(Colors.muted("No caches found."))
        IO.puts("")
      else
        {total_count, total_size} = calculate_all_cache_stats(cache_root, cache_dirs)

        Output.key_value([
          {"Caches found", Colors.info(to_string(total_count))},
          {"Total size", format_bytes(total_size)}
        ])

        IO.puts("")

        if force or confirm_clear_all(total_count, total_size) do
          spinner = Progress.spinner(label: "Clearing all caches...")
          :ok = Persistence.clear(:all)
          Progress.stop_spinner(spinner, Colors.success("✓ All caches cleared successfully"))
          IO.puts("")
        else
          IO.puts(Colors.muted("Cancelled."))
          IO.puts("")
        end
      end
    else
      IO.puts(Colors.muted("No cache directory found."))
      IO.puts("")
    end
  end

  defp clear_older_than(days, force) when days > 0 do
    Output.section("Clear Old Caches")
    IO.puts(Colors.info("Looking for caches older than #{days} day(s)..."))
    IO.puts("")

    cache_root = Path.join(System.user_home!(), ".cache/ragex")

    if File.exists?(cache_root) do
      cutoff_time = System.os_time(:second) - days * 24 * 60 * 60
      old_caches = find_old_caches(cache_root, cutoff_time)

      if Enum.empty?(old_caches) do
        IO.puts(Colors.success("No caches older than #{days} day(s) found."))
        IO.puts("")
      else
        count = length(old_caches)
        total_size = Enum.reduce(old_caches, 0, fn {_, size, _}, acc -> acc + size end)

        Output.key_value([
          {"Old caches found", Colors.warning(to_string(count))},
          {"Total size", format_bytes(total_size)}
        ])

        IO.puts("")

        if force or confirm_clear_old(count, total_size, days) do
          spinner = Progress.spinner(label: "Clearing old caches...")
          :ok = Persistence.clear({:older_than, days})
          Progress.stop_spinner(spinner, Colors.success("✓ Old caches cleared successfully"))
          IO.puts("")
        else
          IO.puts(Colors.muted("Cancelled."))
          IO.puts("")
        end
      end
    else
      IO.puts(Colors.muted("No cache directory found."))
      IO.puts("")
    end
  end

  defp clear_older_than(_days, _force) do
    IO.puts(Colors.error("Error: --older-than requires a positive number of days"))
    IO.puts("")
  end

  defp calculate_all_cache_stats(cache_root, cache_dirs) do
    Enum.reduce(cache_dirs, {0, 0}, fn project_hash, {count, total_size} ->
      cache_file = Path.join([cache_root, project_hash, "embeddings.ets"])

      if File.exists?(cache_file) do
        stat = File.stat!(cache_file)
        {count + 1, total_size + stat.size}
      else
        {count, total_size}
      end
    end)
  end

  defp find_old_caches(cache_root, cutoff_time) do
    cache_root
    |> File.ls!()
    |> Enum.flat_map(fn project_hash ->
      cache_file = Path.join([cache_root, project_hash, "embeddings.ets"])

      if File.exists?(cache_file) do
        stat = File.stat!(cache_file)
        mtime = :calendar.datetime_to_gregorian_seconds(stat.mtime) - 62_167_219_200

        if mtime < cutoff_time do
          [{project_hash, stat.size, stat.mtime}]
        else
          []
        end
      else
        []
      end
    end)
  end

  defp confirm_clear(stats) do
    IO.puts(Colors.bold("Cache Information:"))

    Output.key_value(
      [
        {"Model", stats.metadata[:model_id]},
        {"Entities", stats.metadata[:entity_count]},
        {"Size", format_bytes(stats.file_size)}
      ],
      indent: 2
    )

    IO.puts("")

    Prompt.confirm("Are you sure you want to clear this cache?", default: :no)
  end

  defp confirm_clear_all(count, total_size) do
    Prompt.confirm(
      "Are you sure you want to clear all #{count} cache(s) (#{format_bytes(total_size)})?",
      default: :no
    )
  end

  defp confirm_clear_old(count, total_size, days) do
    Prompt.confirm(
      "Are you sure you want to clear #{count} cache(s) older than #{days} day(s) (#{format_bytes(total_size)})?",
      default: :no
    )
  end

  defp format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_bytes(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"

  defp format_bytes(bytes) when bytes < 1024 * 1024 * 1024,
    do: "#{Float.round(bytes / (1024 * 1024), 1)} MB"

  defp format_bytes(bytes), do: "#{Float.round(bytes / (1024 * 1024 * 1024), 1)} GB"
end

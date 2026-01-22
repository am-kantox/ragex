defmodule Mix.Tasks.Ragex.Ai.Usage.Stats do
  @moduledoc """
  Display AI provider usage statistics and costs.

  ## Usage

      # Show all providers
      mix ragex.ai.usage.stats
      
      # Show specific provider
      mix ragex.ai.usage.stats --provider openai
      mix ragex.ai.usage.stats --provider anthropic

  Shows request counts, token usage, and estimated costs per provider.
  """

  use Mix.Task
  require Logger

  @shortdoc "Display AI usage statistics"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _} = OptionParser.parse!(args, strict: [provider: :string])

    case Keyword.get(opts, :provider) do
      nil ->
        # Show all providers
        stats = Ragex.AI.Usage.get_stats(:all)

        IO.puts("\n=== AI Usage Statistics (All Providers) ===\n")

        total_requests = 0
        total_tokens = 0
        total_cost = 0.0

        {total_requests, total_tokens, total_cost} =
          Enum.reduce(stats, {total_requests, total_tokens, total_cost}, fn {provider,
                                                                             provider_stats},
                                                                            {req, tok, cost} ->
            IO.puts("--- #{provider} ---")
            print_provider_stats(provider_stats)
            IO.puts("")

            {
              req + provider_stats.total_requests,
              tok + provider_stats.total_tokens,
              cost + provider_stats.estimated_cost
            }
          end)

        IO.puts("=== Total Across All Providers ===")
        IO.puts("Total requests: #{total_requests}")
        IO.puts("Total tokens: #{format_number(total_tokens)}")
        IO.puts("Total estimated cost: $#{Float.round(total_cost, 4)}")
        IO.puts("")

      provider_str ->
        provider = String.to_atom(provider_str)
        stats = Ragex.AI.Usage.get_stats(provider)

        if map_size(stats) == 0 do
          IO.puts("No usage data for provider: #{provider}")
        else
          IO.puts("\n=== AI Usage Statistics (#{provider}) ===\n")
          print_provider_stats(stats)
          IO.puts("")
        end
    end
  end

  defp print_provider_stats(stats) do
    IO.puts("Requests: #{stats.total_requests}")
    IO.puts("Prompt tokens: #{format_number(stats.total_prompt_tokens)}")
    IO.puts("Completion tokens: #{format_number(stats.total_completion_tokens)}")
    IO.puts("Total tokens: #{format_number(stats.total_tokens)}")
    IO.puts("Estimated cost: $#{Float.round(stats.estimated_cost, 4)}")

    if map_size(stats.by_model) > 0 do
      IO.puts("\nBy Model:")

      Enum.each(stats.by_model, fn {model, model_stats} ->
        IO.puts("  #{model}:")
        IO.puts("    Requests: #{model_stats.requests}")
        IO.puts("    Tokens: #{format_number(model_stats.total_tokens)}")
        IO.puts("    Cost: $#{Float.round(model_stats.cost, 4)}")
      end)
    end
  end

  defp format_number(num) when num >= 1_000_000 do
    "#{Float.round(num / 1_000_000, 2)}M"
  end

  defp format_number(num) when num >= 1_000 do
    "#{Float.round(num / 1_000, 2)}K"
  end

  defp format_number(num), do: to_string(num)
end

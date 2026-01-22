defmodule Ragex.RAG.ContextBuilder do
  @moduledoc """
  Formats retrieved code for AI consumption.

  Handles:
  - Context window limits
  - Code snippet formatting
  - Metadata inclusion
  - Summarization for large contexts
  """

  # characters
  @max_context_length 8000

  def build_context(results, opts \\ []) do
    include_code = Keyword.get(opts, :include_code, true)
    max_length = Keyword.get(opts, :max_context_length, @max_context_length)

    context =
      results
      |> Enum.map_join("\n\n---\n\n", &format_result(&1, include_code))
      |> truncate_if_needed(max_length)

    {:ok, context}
  end

  defp format_result(result, include_code) do
    """
    ## #{result[:node_id] || "Unknown"}

    **File**: #{result[:file] || "unknown"}
    **Line**: #{result[:line] || "N/A"}
    **Score**: #{Float.round(result[:score] || 0.0, 3)}
    #{if result[:complexity], do: "**Complexity**: #{inspect(result[:complexity])}", else: ""}
    #{if result[:purity], do: "**Purity**: #{if result[:purity].pure?, do: "Pure", else: "Impure"}", else: ""}

    #{if include_code and result[:code] do
      """
      ```#{result[:language] || ""}
      #{result[:code]}
      ```
      """
    else
      result[:text] || result[:doc] || "No description available"
    end}
    """
  end

  defp truncate_if_needed(context, max_length) when byte_size(context) > max_length do
    truncated = String.slice(context, 0, max_length)
    truncated <> "\n\n... (context truncated)"
  end

  defp truncate_if_needed(context, _max_length), do: context
end

defmodule Ragex.RAG.Pipeline do
  @moduledoc """
  Orchestrates the RAG pipeline: Retrieval → Augmentation → Generation.

  ## Pipeline Steps

  1. **Retrieval**: Query knowledge graph and vector store (hybrid search)
  2. **Context Building**: Format retrieved code for AI consumption
  3. **Prompt Engineering**: Apply templates and inject context
  4. **Generation**: Call AI provider with augmented prompt
  5. **Post-processing**: Parse response, add sources, format output
  """

  require Logger

  alias Ragex.AI.Config
  alias Ragex.RAG.{ContextBuilder, PromptTemplate}
  alias Ragex.Retrieval.Hybrid

  @doc """
  Execute RAG query pipeline.

  ## Options

  - `:limit` - Max retrieval results (default: 10)
  - `:threshold` - Similarity threshold (default: 0.7)
  - `:strategy` - Retrieval strategy: :fusion, :semantic_first, :graph_first
  - `:include_code` - Include full code snippets (default: true)
  - `:provider` - Override AI provider
  - `:system_prompt` - Custom system prompt
  - `:temperature` - AI temperature (default: 0.7)
  """
  def query(user_query, opts \\ []) do
    Logger.info("RAG Pipeline: query='#{user_query}'")

    with {:ok, retrieval_results} <- retrieve(user_query, opts),
         {:ok, context} <- build_context(retrieval_results, opts),
         {:ok, prompt} <- build_prompt(user_query, context, opts),
         {:ok, response} <- generate(prompt, context, opts) do
      format_response(response, retrieval_results)
    end
  end

  @doc """
  Explain code using RAG.
  """
  def explain(target, aspect, opts \\ []) do
    query_text = build_explain_query(target, aspect)

    opts =
      opts
      |> Keyword.put(:system_prompt, explain_system_prompt())
      |> Keyword.put(:limit, 5)

    query(query_text, opts)
  end

  @doc """
  Suggest improvements using RAG.
  """
  def suggest(target, focus, opts \\ []) do
    query_text = build_suggest_query(target, focus)

    opts =
      opts
      |> Keyword.put(:system_prompt, suggest_system_prompt())
      |> Keyword.put(:limit, 3)

    query(query_text, opts)
  end

  # Private

  defp retrieve(query, opts) do
    limit = Keyword.get(opts, :limit, 10)
    threshold = Keyword.get(opts, :threshold, 0.7)
    strategy = Keyword.get(opts, :strategy, :fusion)

    case Hybrid.search(query, limit: limit, threshold: threshold, strategy: strategy) do
      {:ok, [_ | _] = results} ->
        {:ok, results}

      {:ok, []} ->
        {:error, :no_results_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_context(results, opts) do
    ContextBuilder.build_context(results, opts)
  end

  defp build_prompt(user_query, context, opts) do
    system_prompt = Keyword.get(opts, :system_prompt, default_system_prompt())

    prompt =
      PromptTemplate.render(:query, %{
        system_prompt: system_prompt,
        context: context,
        query: user_query
      })

    {:ok, prompt}
  end

  defp generate(prompt, context, opts) do
    provider = get_provider(opts)

    ai_opts = [
      temperature: Keyword.get(opts, :temperature, 0.7),
      max_tokens: Keyword.get(opts, :max_tokens, 2048)
    ]

    provider.generate(prompt, %{context: context}, ai_opts)
  end

  defp format_response({:ok, ai_response}, retrieval_results) do
    {:ok,
     %{
       content: ai_response.content,
       sources: format_sources(retrieval_results),
       model: ai_response.model,
       usage: ai_response.usage,
       metadata: %{
         retrieval_count: length(retrieval_results),
         timestamp: DateTime.utc_now()
       }
     }}
  end

  defp format_response({:error, reason}, _results) do
    {:error, reason}
  end

  defp format_sources(results) do
    Enum.map(results, fn result ->
      %{
        file: result[:file],
        node_id: result[:node_id],
        score: Float.round(result[:score] || 0.0, 3),
        line: result[:line]
      }
    end)
  end

  defp get_provider(opts) do
    case Keyword.get(opts, :provider) do
      nil -> Config.provider()
      provider_atom when is_atom(provider_atom) -> provider_module(provider_atom)
    end
  end

  defp provider_module(:deepseek_r1), do: Ragex.AI.Provider.DeepSeekR1
  defp provider_module(_), do: Config.provider()

  defp default_system_prompt do
    """
    You are an expert code assistant with deep knowledge of software engineering.
    You have access to a codebase and can answer questions about its structure,
    functionality, and best practices.

    Your responses should be:
    - Accurate and based on the provided code context
    - Concise but comprehensive
    - Include specific file/function references when relevant
    - Suggest improvements when appropriate
    """
  end

  defp explain_system_prompt do
    """
    You are a code documentation expert. Explain the provided code clearly and thoroughly.
    Focus on: purpose, behavior, dependencies, and potential issues.
    Use simple language suitable for both beginners and experts.
    """
  end

  defp suggest_system_prompt do
    """
    You are a code reviewer focused on suggesting improvements.
    Provide actionable, specific recommendations with examples.
    Consider: performance, readability, maintainability, and testing.
    """
  end

  defp build_explain_query(target, aspect) do
    "Explain the #{aspect} of #{target}"
  end

  defp build_suggest_query(target, focus) do
    "Suggest #{focus} improvements for #{target}"
  end
end

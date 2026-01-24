defmodule Ragex.AI.Features.Cache do
  @moduledoc """
  Feature-aware wrapper around Ragex.AI.Cache.

  Provides convenience functions that automatically use feature-specific
  cache TTLs and configuration from Features.Config.

  ## Usage

      alias Ragex.AI.Features.Cache

      # Get cached response for validation errors
      case Cache.get(:validation_error_explanation, error, context) do
        {:ok, response} -> response
        {:error, :not_found} ->
          # Generate and cache
          response = generate_ai_response(...)
          Cache.put(:validation_error_explanation, error, context, response)
          response
      end

      # Or use fetch! helper
      response = Cache.fetch!(:refactor_preview_commentary, params, context, fn ->
        generate_ai_response(...)
      end)
  """

  alias Ragex.AI.{Cache, Features.Config}
  require Logger

  @type feature :: Config.feature()
  @type cache_result :: {:ok, any()} | {:error, :not_found}

  @doc """
  Get a cached AI response for a specific feature.

  Automatically uses feature-specific TTL and configuration.

  ## Parameters
  - `feature` - Feature identifier atom
  - `query` - Query or input data
  - `context` - Context map
  - `opts` - Additional options (merged with feature config)

  ## Returns
  - `{:ok, response}` if cached
  - `{:error, :not_found}` if not cached or expired
  """
  @spec get(feature(), any(), any(), keyword()) :: cache_result()
  def get(feature, query, context, opts \\ []) do
    feature_config = Config.get_feature_config(feature)
    merged_opts = merge_opts(feature_config, opts)

    Cache.get(feature, query, context, merged_opts)
  end

  @doc """
  Store an AI response in the cache for a specific feature.

  Automatically uses feature-specific TTL and configuration.

  ## Parameters
  - `feature` - Feature identifier atom
  - `query` - Query or input data
  - `context` - Context map
  - `response` - Response to cache
  - `opts` - Additional options

  ## Returns
  - `:ok`
  """
  @spec put(feature(), any(), any(), any(), keyword()) :: :ok
  def put(feature, query, context, response, opts \\ []) do
    feature_config = Config.get_feature_config(feature)
    merged_opts = merge_opts(feature_config, opts)

    Cache.put(feature, query, context, response, merged_opts)
  end

  @doc """
  Fetch from cache or generate if not found.

  This is the recommended way to use the cache - it handles both
  retrieval and storage in one call.

  ## Parameters
  - `feature` - Feature identifier atom
  - `query` - Query or input data
  - `context` - Context map
  - `generator_fn` - Function to call if cache miss (arity 0)
  - `opts` - Additional options

  ## Returns
  - Cached or freshly generated response

  ## Examples

      response = Cache.fetch!(
        :validation_error_explanation,
        error,
        context,
        fn -> ValidationAI.generate_explanation(error, context) end
      )
  """
  @spec fetch!(feature(), any(), any(), function(), keyword()) :: any()
  def fetch!(feature, query, context, generator_fn, opts \\ []) do
    case get(feature, query, context, opts) do
      {:ok, response} ->
        Logger.debug("Cache hit for #{feature}")
        response

      {:error, :not_found} ->
        Logger.debug("Cache miss for #{feature}, generating...")
        response = generator_fn.()
        put(feature, query, context, response, opts)
        response
    end
  end

  @doc """
  Fetch from cache or generate if not found (with error handling).

  Like `fetch!/4` but propagates errors from the generator function.

  ## Returns
  - `{:ok, response}` on success (cached or generated)
  - `{:error, reason}` if generation fails
  """
  @spec fetch(feature(), any(), any(), function(), keyword()) ::
          {:ok, any()} | {:error, term()}
  def fetch(feature, query, context, generator_fn, opts \\ []) do
    case get(feature, query, context, opts) do
      {:ok, response} ->
        Logger.debug("Cache hit for #{feature}")
        {:ok, response}

      {:error, :not_found} ->
        Logger.debug("Cache miss for #{feature}, generating...")

        case generator_fn.() do
          {:ok, response} = result ->
            put(feature, query, context, response, opts)
            result

          {:error, _reason} = error ->
            error
        end
    end
  end

  @doc """
  Clear cache for a specific feature.

  Note: Currently clears the entire AI cache. Future versions may
  implement per-feature cache partitioning.

  ## Parameters
  - `feature` - Feature identifier atom

  ## Returns
  - `:ok`
  """
  @spec clear(feature()) :: :ok
  def clear(feature) do
    Logger.info("Clearing AI cache for feature: #{feature}")
    Cache.clear(feature)
  end

  @doc """
  Get cache statistics for all features.

  Returns general cache stats plus per-feature breakdown if available.

  ## Returns
  - Map of statistics
  """
  @spec stats() :: map()
  def stats do
    base_stats = Cache.stats()

    # Add feature-specific context
    Map.put(base_stats, :features, Config.list_features())
  end

  @doc """
  Check if caching is enabled for a specific feature.

  Takes into account:
  1. Global AI cache enabled flag
  2. Feature-specific enabled flag
  3. Per-call overrides

  ## Parameters
  - `feature` - Feature identifier atom
  - `opts` - Options with potential overrides

  ## Returns
  - `true` if caching should be used
  - `false` otherwise
  """
  @spec enabled?(feature(), keyword()) :: boolean()
  def enabled?(feature, opts \\ []) do
    # Check if AI features are enabled at all
    with true <- Config.enabled?(feature, opts) do
      :ragex
      |> Application.get_env(:ai_cache, [])
      |> Keyword.get(:enabled, true)
    end
  end

  @doc """
  Warm up the cache with pre-computed responses.

  Useful for seeding the cache with known common patterns.

  ## Parameters
  - `entries` - List of {feature, query, context, response} tuples

  ## Returns
  - `:ok`

  ## Examples

      Cache.warm_up([
        {:validation_error_explanation, error1, context1, response1},
        {:refactor_preview_commentary, params1, context1, response1}
      ])
  """
  @spec warm_up([{feature(), any(), any(), any()}]) :: :ok
  def warm_up(entries) when is_list(entries) do
    Logger.info("Warming up AI cache with #{length(entries)} entries")

    Enum.each(entries, fn {feature, query, context, response} ->
      put(feature, query, context, response)
    end)

    :ok
  end

  # Private functions

  defp merge_opts(feature_config, opts) do
    # Merge feature config with call-time opts (opts take precedence)
    [
      provider: Application.get_env(:ragex, :ai, []) |> Keyword.get(:default_provider),
      model: get_model_for_provider(),
      temperature: feature_config.temperature,
      max_tokens: feature_config.max_tokens,
      ttl: feature_config.cache_ttl
    ]
    |> Keyword.merge(opts)
  end

  defp get_model_for_provider do
    provider =
      Application.get_env(:ragex, :ai, []) |> Keyword.get(:default_provider, :deepseek_r1)

    providers = Application.get_env(:ragex, :ai_providers, [])
    provider_config = Keyword.get(providers, provider, [])

    Keyword.get(provider_config, :model, "unknown")
  end
end

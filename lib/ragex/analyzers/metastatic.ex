defmodule Ragex.Analyzers.Metastatic do
  @moduledoc """
  Analyzer implementation using Metastatic MetaAST library.

  Provides richer semantic analysis compared to native regex-based parsers:
  - Cross-language semantic equivalence
  - Purity analysis
  - Complexity metrics
  - Three-layer MetaAST (M2.1/M2.2/M2.3)

  NOTE: This is a hybrid approach that uses Metastatic for parsing and validation,
  then falls back to native analyzers for detailed extraction. Future versions
  will do full MetaAST extraction.
  """

  @behaviour Ragex.Analyzers.Behaviour

  require Logger
  alias Metastatic.{Builder, Document}

  alias Ragex.Analyzers.Elixir, as: ExAnalyzer
  alias Ragex.Analyzers.Erlang, as: ErlAnalyzer
  alias Ragex.Analyzers.Python, as: PyAnalyzer

  @impl true
  def analyze(source, file_path) do
    language = detect_language(file_path)

    case Builder.from_source(source, language) do
      {:ok, doc} ->
        # For now, use native analyzer but enrich with Metastatic data
        # This gives us immediate functionality while we build out full MetaAST extraction
        analyze_with_enrichment(source, file_path, language, doc)

      {:error, reason} ->
        Logger.warning(
          "Metastatic parsing failed for #{file_path}: #{inspect(reason)}. " <>
            "Falling back to native analyzer."
        )

        fallback_analyze(source, file_path, language)
    end
  end

  @impl true
  def supported_extensions do
    # Metastatic supports these languages
    [".ex", ".exs", ".erl", ".hrl", ".py", ".rb"]
  end

  # Private

  defp detect_language(file_path) do
    case Metastatic.Adapter.detect_language(file_path) do
      {:ok, lang} -> lang
      {:error, _} -> :unknown
    end
  end

  defp analyze_with_enrichment(source, file_path, language, %Document{} = doc) do
    # Get base analysis from native analyzer
    case fallback_analyze(source, file_path, language) do
      {:ok, analysis} ->
        # Enrich with Metastatic data
        {:ok, enrich_analysis(analysis, doc)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp enrich_analysis(analysis, %Document{ast: meta_ast, metadata: metadata}) do
    # Add MetaAST information to the analysis
    analysis
    |> Map.put(:meta_ast, meta_ast)
    |> Map.put(:meta_ast_metadata, metadata)
    |> enrich_functions_with_metastatic(meta_ast)
  end

  defp enrich_functions_with_metastatic(analysis, _meta_ast) do
    # For now, just pass through
    # [TODO]: Add purity analysis, complexity metrics, etc.
    analysis
  end

  defp fallback_analyze(source, file_path, language) do
    # Fall back to native analyzers if feature flag is enabled
    if Application.get_env(:ragex, :features)[:fallback_to_native_analyzers] do
      case language do
        :elixir -> ExAnalyzer.analyze(source, file_path)
        :erlang -> ErlAnalyzer.analyze(source, file_path)
        :python -> PyAnalyzer.analyze(source, file_path)
        _ -> {:error, :no_fallback_analyzer}
      end
    else
      {:error, :metastatic_failed_no_fallback}
    end
  end
end

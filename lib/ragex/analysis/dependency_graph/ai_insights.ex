defmodule Ragex.Analysis.DependencyGraph.AIInsights do
  @moduledoc """
  AI-powered context-aware insights for dependency analysis.

  Uses AI to provide architectural recommendations for high-coupling modules,
  distinguishing between "good" coupling (central services) and "bad" coupling
  (tangled dependencies), and suggesting specific refactoring strategies.

  ## Features

  - Context-aware coupling evaluation
  - Architectural pattern recognition
  - Refactoring strategy recommendations
  - Technical debt assessment
  - Circular dependency resolution strategies

  ## Usage

      alias Ragex.Analysis.DependencyGraph.AIInsights

      # Get insights for a high-coupling module
      coupling_data = %{
        module: MyApp.UserService,
        coupling_in: 15,
        coupling_out: 12,
        instability: 0.55,
        dependencies: [...]
      }

      {:ok, insights} = AIInsights.analyze_coupling(coupling_data)
      # => %{
      #   coupling_assessment: :concerning,
      #   reasoning: "High coupling due to...",
      #   recommendations: ["Extract user validation...", ...],
      #   refactoring_priority: :high
      # }

      # Analyze circular dependency
      {:ok, resolution} = AIInsights.resolve_circular_dependency(cycle_data)

  ## Configuration

      config :ragex, :ai_features,
        dependency_insights: true
  """

  alias Ragex.AI.Features.{Cache, Config, Context}
  alias Ragex.AI.Registry
  alias Ragex.RAG.Pipeline

  require Logger

  @type coupling_data :: map()
  @type cycle_data :: map()
  @type coupling_insights :: %{
          coupling_assessment: :acceptable | :concerning | :problematic,
          reasoning: String.t(),
          recommendations: [String.t()],
          refactoring_priority: :low | :medium | :high,
          technical_debt_score: float()
        }
  @type cycle_resolution :: %{
          resolution_strategy: String.t(),
          steps: [String.t()],
          estimated_effort: :small | :medium | :large,
          risks: [String.t()]
        }

  @doc """
  Analyze coupling metrics for a module and provide AI insights.

  Uses AI to evaluate whether coupling is appropriate given the module's
  architectural role, and provides specific recommendations.

  ## Parameters
  - `coupling_data` - Module coupling metrics
  - `opts` - Options:
    - `:ai_insights` - Enable/disable AI (default: from config)

  ## Returns
  - `{:ok, coupling_insights}` - Assessment and recommendations
  - `{:error, reason}` - Error if analysis fails

  ## Examples

      coupling_data = %{
        module: MyApp.UserService,
        coupling_in: 15,
        coupling_out: 8,
        instability: 0.35,
        dependencies: [MyApp.Repo, MyApp.Email, MyApp.Cache],
        dependents: [MyApp.Web.UserController, ...]
      }

      {:ok, insights} = AIInsights.analyze_coupling(coupling_data)
      # => %{
      #   coupling_assessment: :acceptable,
      #   reasoning: "UserService is a central service...",
      #   recommendations: ["Consider extracting email logic..."],
      #   refactoring_priority: :medium,
      #   technical_debt_score: 0.4
      # }
  """
  @spec analyze_coupling(coupling_data(), keyword()) ::
          {:ok, coupling_insights()} | {:error, term()}
  def analyze_coupling(coupling_data, opts \\ []) do
    if Config.enabled?(:dependency_insights, opts) do
      do_analyze_coupling(coupling_data, opts)
    else
      {:error, :ai_insights_disabled}
    end
  end

  @doc """
  Analyze a circular dependency and suggest resolution strategies.

  Uses AI to understand the architectural issue and provide step-by-step
  refactoring guidance.

  ## Parameters
  - `cycle_data` - Circular dependency information
  - `opts` - Options (same as analyze_coupling/2)

  ## Returns
  - `{:ok, cycle_resolution}` - Resolution strategy with steps
  - `{:error, reason}` - Error if analysis fails

  ## Examples

      cycle_data = %{
        cycle: [ModuleA, ModuleB, ModuleC, ModuleA],
        dependencies: [
          {ModuleA, ModuleB, [:calls]},
          {ModuleB, ModuleC, [:imports]},
          {ModuleC, ModuleA, [:calls]}
        ]
      }

      {:ok, resolution} = AIInsights.resolve_circular_dependency(cycle_data)
      # => %{
      #   resolution_strategy: "Break cycle by extracting shared interface",
      #   steps: ["Create ModuleD with shared functions", ...],
      #   estimated_effort: :medium,
      #   risks: ["May require updating tests"]
      # }
  """
  @spec resolve_circular_dependency(cycle_data(), keyword()) ::
          {:ok, cycle_resolution()} | {:error, term()}
  def resolve_circular_dependency(cycle_data, opts \\ []) do
    if Config.enabled?(:dependency_insights, opts) do
      do_resolve_circular_dependency(cycle_data, opts)
    else
      {:error, :ai_insights_disabled}
    end
  end

  @doc """
  Analyze multiple modules in batch.
  """
  @spec analyze_batch([coupling_data()], keyword()) ::
          {:ok, [coupling_insights()]} | {:error, term()}
  def analyze_batch(coupling_list, opts \\ []) do
    results =
      coupling_list
      |> Task.async_stream(
        fn data ->
          case analyze_coupling(data, opts) do
            {:ok, insights} -> Map.merge(data, %{ai_insights: insights})
            {:error, _} -> data
          end
        end,
        timeout: get_timeout(opts) * length(coupling_list),
        max_concurrency: 3
      )
      |> Enum.map(fn {:ok, result} -> result end)

    {:ok, results}
  end

  @doc """
  Check if AI dependency insights are currently enabled.
  """
  @spec enabled?(keyword()) :: boolean()
  def enabled?(opts \\ []) do
    Config.enabled?(:dependency_insights, opts)
  end

  @doc """
  Clear the insights cache.
  """
  @spec clear_cache() :: :ok
  def clear_cache do
    Cache.clear(:dependency_insights)
  end

  # Private functions

  defp do_analyze_coupling(coupling_data, opts) do
    module_name = coupling_data[:module]

    # Build coupling metrics map
    metrics = %{
      afferent: coupling_data[:coupling_in] || 0,
      efferent: coupling_data[:coupling_out] || 0,
      instability: coupling_data[:instability] || 0.5
    }

    # Build context for AI
    context = Context.for_dependency_insights(module_name, metrics, opts)

    # Try to get insights from cache or generate
    Cache.fetch(
      :dependency_insights,
      {:coupling, module_name},
      context,
      fn ->
        generate_coupling_insights(coupling_data, context, opts)
      end,
      opts
    )
  end

  defp do_resolve_circular_dependency(cycle_data, opts) do
    # Generate cache key from cycle
    cycle_key = generate_cycle_key(cycle_data)

    # Build context for AI - use first module in cycle as primary
    cycle = cycle_data[:cycle] || []
    first_module = List.first(cycle) || :unknown
    metrics = %{cycle_length: length(cycle)}

    context = Context.for_dependency_insights(first_module, metrics, opts)

    # Try to get resolution from cache or generate
    Cache.fetch(
      :dependency_insights,
      {:circular, cycle_key},
      context,
      fn ->
        generate_cycle_resolution(cycle_data, context, opts)
      end,
      opts
    )
  end

  defp generate_coupling_insights(coupling_data, context, opts) do
    # Build prompt for AI
    prompt = build_coupling_prompt(coupling_data, context)

    # Get feature config
    feature_config = Config.get_feature_config(:dependency_insights)

    # Prepare RAG query options
    rag_opts =
      [
        temperature: feature_config.temperature,
        max_tokens: feature_config.max_tokens,
        limit: 5,
        threshold: 0.5,
        system_prompt: coupling_system_prompt()
      ]
      |> maybe_add_provider(opts)

    # Call RAG pipeline
    case Pipeline.query(prompt, rag_opts) do
      {:ok, response} ->
        parse_coupling_response(response)

      {:error, :no_results_found} ->
        Logger.debug("No RAG results for coupling insights, using direct AI")
        call_direct_ai(prompt, rag_opts, :coupling)

      {:error, reason} = error ->
        Logger.warning("RAG query failed for coupling insights: #{inspect(reason)}")
        error
    end
  rescue
    e ->
      Logger.error("Exception generating coupling insights: #{inspect(e)}")
      {:error, {:insights_failed, Exception.message(e)}}
  end

  defp generate_cycle_resolution(cycle_data, context, opts) do
    # Build prompt for AI
    prompt = build_cycle_prompt(cycle_data, context)

    # Get feature config
    feature_config = Config.get_feature_config(:dependency_insights)

    # Prepare RAG query options
    rag_opts =
      [
        temperature: feature_config.temperature,
        max_tokens: feature_config.max_tokens,
        limit: 5,
        threshold: 0.5,
        system_prompt: cycle_system_prompt()
      ]
      |> maybe_add_provider(opts)

    # Call RAG pipeline
    case Pipeline.query(prompt, rag_opts) do
      {:ok, response} ->
        parse_cycle_response(response)

      {:error, :no_results_found} ->
        Logger.debug("No RAG results for cycle resolution, using direct AI")
        call_direct_ai(prompt, rag_opts, :cycle)

      {:error, reason} = error ->
        Logger.warning("RAG query failed for cycle resolution: #{inspect(reason)}")
        error
    end
  rescue
    e ->
      Logger.error("Exception generating cycle resolution: #{inspect(e)}")
      {:error, {:resolution_failed, Exception.message(e)}}
  end

  defp call_direct_ai(prompt, opts, type) do
    with {:ok, provider} <- Registry.get_provider_or_default(opts[:provider]) do
      ai_opts = [
        temperature: opts[:temperature] || 0.6,
        max_tokens: opts[:max_tokens] || 700
      ]

      case provider.generate(prompt, ai_opts) do
        {:ok, response} ->
          text = %{answer: response.content}

          case type do
            :coupling -> parse_coupling_response(text)
            :cycle -> parse_cycle_response(text)
          end

        error ->
          error
      end
    end
  end

  defp build_coupling_prompt(coupling_data, context) do
    context_str = Context.to_prompt_string(context)

    module_name = coupling_data[:module]
    coupling_in = coupling_data[:coupling_in] || 0
    coupling_out = coupling_data[:coupling_out] || 0
    instability = coupling_data[:instability] || 0.5

    dependencies = format_list(coupling_data[:dependencies] || [])
    dependents = format_list(coupling_data[:dependents] || [])

    """
    #{context_str}

    ## Coupling Analysis

    **Module**: #{module_name}
    **Afferent Coupling (Ca)**: #{coupling_in} modules depend on this
    **Efferent Coupling (Ce)**: #{coupling_out} dependencies
    **Instability**: #{Float.round(instability, 2)}

    **Dependencies (Ce)**:
    #{dependencies}

    **Dependents (Ca)**:
    #{dependents}

    ## Task

    Evaluate this module's coupling in architectural context:
    - Is high coupling justified? (central service vs tangled code)
    - Does the role match the metrics?
    - What specific improvements would help?

    Provide:
    1. **ASSESSMENT**: Coupling level (ACCEPTABLE/CONCERNING/PROBLEMATIC)
    2. **REASONING**: Why? (2-4 sentences, architectural context)
    3. **RECOMMENDATIONS**: Specific improvements (3-5 bullet points)
    4. **PRIORITY**: Refactoring urgency (LOW/MEDIUM/HIGH)
    5. **DEBT_SCORE**: Technical debt (0.0 = none, 1.0 = severe)

    Format as:

    ASSESSMENT: <ACCEPTABLE/CONCERNING/PROBLEMATIC>
    REASONING: <reasoning text>
    RECOMMENDATIONS:
    - <recommendation 1>
    - <recommendation 2>
    - <recommendation 3>
    PRIORITY: <LOW/MEDIUM/HIGH>
    DEBT_SCORE: <0.0-1.0>

    Be specific to this codebase and architectural patterns.
    """
  end

  defp build_cycle_prompt(cycle_data, context) do
    context_str = Context.to_prompt_string(context)

    cycle = cycle_data[:cycle] || []
    dependencies = cycle_data[:dependencies] || []

    cycle_str = Enum.map_join(cycle, " -> ", &to_string/1)

    deps_str =
      Enum.map_join(dependencies, "\n", fn {from, to, types} ->
        "- #{from} -> #{to} (#{Enum.join(types, ", ")})"
      end)

    """
    #{context_str}

    ## Circular Dependency

    **Cycle**: #{cycle_str}

    **Dependencies**:
    #{deps_str}

    ## Task

    Provide a strategy to break this circular dependency:
    - What's the best refactoring approach?
    - Step-by-step resolution plan
    - Estimated effort and risks

    Provide:
    1. **STRATEGY**: One-sentence strategy description
    2. **STEPS**: Step-by-step plan (3-6 numbered steps)
    3. **EFFORT**: Implementation size (SMALL/MEDIUM/LARGE)
    4. **RISKS**: Potential issues (2-4 bullet points)

    Format as:

    STRATEGY: <strategy description>
    STEPS:
    1. <step 1>
    2. <step 2>
    3. <step 3>
    EFFORT: <SMALL/MEDIUM/LARGE>
    RISKS:
    - <risk 1>
    - <risk 2>

    Be practical and specific to this codebase.
    """
  end

  defp coupling_system_prompt do
    """
    You are a software architecture advisor helping evaluate module coupling.

    Your role:
    - Distinguish justified coupling from architectural problems
    - Recognize architectural patterns (layered, hexagonal, microkernel)
    - Provide actionable, specific recommendations
    - Consider maintainability and team velocity
    - Balance ideal architecture with pragmatic constraints

    High coupling isn't always bad - central services naturally have high Ca.
    Focus on whether coupling matches the module's architectural role.
    """
  end

  defp cycle_system_prompt do
    """
    You are a software architecture advisor helping resolve circular dependencies.

    Your role:
    - Identify root cause of circular dependencies
    - Suggest practical refactoring strategies
    - Provide step-by-step implementation plans
    - Estimate effort realistically
    - Flag potential risks

    Common strategies: dependency inversion, extract interface, event-driven,
    move shared code, split modules. Choose the best fit for this case.
    """
  end

  defp parse_coupling_response(response) when is_map(response) do
    text = response[:answer] || response[:content] || ""
    parse_coupling_text(text)
  end

  defp parse_coupling_text(text) do
    assessment = extract_assessment(text)
    reasoning = extract_section(text, "REASONING")
    recommendations = extract_list(text, "RECOMMENDATIONS")
    priority = extract_priority(text)
    debt_score = extract_debt_score(text)

    {:ok,
     %{
       coupling_assessment: assessment,
       reasoning: reasoning || "Coupling analysis complete.",
       recommendations: recommendations,
       refactoring_priority: priority,
       technical_debt_score: debt_score,
       analyzed_at: DateTime.utc_now()
     }}
  end

  defp parse_cycle_response(response) when is_map(response) do
    text = response[:answer] || response[:content] || ""
    parse_cycle_text(text)
  end

  defp parse_cycle_text(text) do
    strategy = extract_section(text, "STRATEGY")
    steps = extract_list(text, "STEPS", numbered: true)
    effort = extract_effort(text)
    risks = extract_list(text, "RISKS")

    {:ok,
     %{
       resolution_strategy: strategy || "Break circular dependency",
       steps: steps,
       estimated_effort: effort,
       risks: risks,
       analyzed_at: DateTime.utc_now()
     }}
  end

  defp extract_assessment(text) do
    case Regex.run(~r/ASSESSMENT:\s*(ACCEPTABLE|CONCERNING|PROBLEMATIC)/i, text) do
      [_, "ACCEPTABLE"] -> :acceptable
      [_, "CONCERNING"] -> :concerning
      [_, "PROBLEMATIC"] -> :problematic
      _ -> :concerning
    end
  end

  defp extract_priority(text) do
    case Regex.run(~r/PRIORITY:\s*(LOW|MEDIUM|HIGH)/i, text) do
      [_, "LOW"] -> :low
      [_, "MEDIUM"] -> :medium
      [_, "HIGH"] -> :high
      _ -> :medium
    end
  end

  defp extract_effort(text) do
    case Regex.run(~r/EFFORT:\s*(SMALL|MEDIUM|LARGE)/i, text) do
      [_, "SMALL"] -> :small
      [_, "MEDIUM"] -> :medium
      [_, "LARGE"] -> :large
      _ -> :medium
    end
  end

  defp extract_debt_score(text) do
    case Regex.run(~r/DEBT_SCORE:\s*([\d.]+)/, text) do
      [_, score_str] ->
        case Float.parse(score_str) do
          {score, _} -> max(0.0, min(1.0, score))
          :error -> 0.5
        end

      _ ->
        0.5
    end
  end

  defp extract_section(text, section_name) do
    # Match until next section or list
    case Regex.run(~r/#{section_name}:\s*(.+?)(?=\n[A-Z_]+:|$)/s, text) do
      [_, content] -> String.trim(content)
      _ -> nil
    end
  end

  defp extract_list(text, section_name, opts \\ []) do
    numbered = Keyword.get(opts, :numbered, false)

    # Extract section content
    pattern =
      if numbered do
        ~r/#{section_name}:\s*((?:\d+\.\s*.+?\n?)+)/s
      else
        ~r/#{section_name}:\s*((?:-\s*.+?\n?)+)/s
      end

    case Regex.run(pattern, text) do
      [_, content] ->
        content
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(fn line ->
          line
          |> String.replace(~r/^(\d+\.|-)\s*/, "")
          |> String.trim()
        end)
        |> Enum.reject(&(&1 == ""))

      _ ->
        []
    end
  end

  defp format_list([]), do: "- (none)"

  defp format_list(items) do
    items
    |> Enum.take(10)
    |> Enum.map_join("\n", &"- #{&1}")
  end

  defp generate_cycle_key(cycle_data) do
    cycle = cycle_data[:cycle] || []

    cycle
    |> Enum.map(&to_string/1)
    |> Enum.sort()
    |> Enum.join("|")
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
    |> String.slice(0..15)
  end

  defp maybe_add_provider(opts, call_opts) do
    case Keyword.get(call_opts, :provider) do
      nil -> opts
      provider -> Keyword.put(opts, :provider, provider)
    end
  end

  defp get_timeout(opts) do
    feature_config = Config.get_feature_config(:dependency_insights)
    Keyword.get(opts, :timeout, feature_config.timeout)
  end
end

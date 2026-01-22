defmodule Ragex.AI.Provider.DeepSeekR1 do
  @moduledoc """
  DeepSeek R1 API provider implementation.

  Uses the DeepSeek API (OpenAI-compatible):
  - Base URL: https://api.deepseek.com
  - Models: deepseek-chat (non-thinking), deepseek-reasoner (thinking)
  - API Docs: https://api-docs.deepseek.com/

  ## Configuration

  In config/runtime.exs:
      config :ragex, :ai,
        api_key: System.fetch_env!("DEEPSEEK_API_KEY")

  In config/config.exs:
      config :ragex, :ai,
        provider: :deepseek_r1,
        endpoint: "https://api.deepseek.com",
        model: "deepseek-chat"
  """

  @behaviour Ragex.AI.Behaviour

  require Logger
  alias Ragex.AI.Config

  @impl true
  def generate(prompt, context, opts \\ []) do
    config = Config.api_config()
    opts = Config.generation_opts(opts)

    # Build request body
    body = build_request_body(prompt, context, opts, config.model)

    # Make HTTP request using Req
    case make_request(config, body, stream: false) do
      {:ok, response} ->
        parse_response(response)

      {:error, reason} ->
        Logger.error("DeepSeek API error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def stream_generate(prompt, context, opts \\ []) do
    config = Config.api_config()
    opts = Config.generation_opts(Keyword.put(opts, :stream, true))

    body = build_request_body(prompt, context, opts, config.model)

    case make_request(config, body, stream: true) do
      {:ok, stream} ->
        {:ok, Stream.map(stream, &parse_stream_chunk/1)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def validate_config do
    config = Config.api_config()

    cond do
      is_nil(config.api_key) or config.api_key == "" ->
        {:error, "DEEPSEEK_API_KEY not set"}

      not valid_endpoint?(config.endpoint) ->
        {:error, "Invalid endpoint: #{config.endpoint}"}

      not valid_model?(config.model) ->
        {:error, "Invalid model: #{config.model}"}

      true ->
        # Optional: test API call - skip for now to avoid startup delay
        :ok
    end
  end

  @impl true
  def info do
    %{
      name: "DeepSeek R1",
      provider: :deepseek_r1,
      models: ["deepseek-chat", "deepseek-reasoner"],
      capabilities: [:generate, :stream, :function_calling],
      api_version: "v1",
      docs_url: "https://api-docs.deepseek.com/"
    }
  end

  # Private functions

  defp build_request_body(prompt, context, opts, model) do
    messages = build_messages(prompt, context, opts)

    %{
      model: Keyword.get(opts, :model, model),
      messages: messages,
      temperature: Keyword.get(opts, :temperature, 0.7),
      max_tokens: Keyword.get(opts, :max_tokens, 2048),
      stream: Keyword.get(opts, :stream, false)
    }
    |> maybe_add_system_prompt(opts)
  end

  defp build_messages(prompt, nil, _opts) do
    [%{role: "user", content: prompt}]
  end

  defp build_messages(prompt, context, opts) when is_map(context) do
    context_content = format_context(context, opts)

    system_prompt = Keyword.get(opts, :system_prompt)

    messages =
      if system_prompt do
        [%{role: "system", content: system_prompt}]
      else
        []
      end

    messages ++
      [
        %{role: "user", content: context_content},
        %{role: "user", content: prompt}
      ]
  end

  defp format_context(context, _opts) do
    """
    # Code Context

    #{format_code_snippets(context)}

    #{format_metadata(context)}
    """
  end

  defp format_code_snippets(%{results: results}) when is_list(results) do
    results
    |> Enum.take(10)
    |> Enum.map_join("\n\n", fn result ->
      """
      ## #{result[:node_id]}
      File: #{result[:file] || "unknown"}
      Score: #{Float.round(result[:score] || 0.0, 3)}

      ```#{result[:language] || ""}
      #{result[:code] || result[:text] || "No code available"}
      ```
      """
    end)
  end

  defp format_code_snippets(_), do: ""

  defp format_metadata(%{metadata: meta}) when is_map(meta) do
    """
    ## Metadata
    #{inspect(meta, pretty: true, limit: :infinity)}
    """
  end

  defp format_metadata(_), do: ""

  defp maybe_add_system_prompt(body, opts) do
    case Keyword.get(opts, :system_prompt) do
      nil -> body
      # Already added to messages
      _system_prompt -> body
    end
  end

  defp make_request(config, body, opts) do
    url = "#{config.endpoint}/chat/completions"

    headers = [
      {"authorization", "Bearer #{config.api_key}"},
      {"content-type", "application/json"}
    ]

    req_opts = [
      url: url,
      method: :post,
      headers: headers,
      json: body,
      receive_timeout: 60_000
    ]

    req_opts =
      if opts[:stream] do
        Keyword.put(req_opts, :into, :self)
      else
        req_opts
      end

    case Req.request(req_opts) do
      {:ok, %{status: 200} = response} ->
        if opts[:stream] do
          {:ok, response.body}
        else
          {:ok, response}
        end

      {:ok, %{status: status, body: body}} ->
        {:error, "HTTP #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_response(%{body: body}) when is_map(body) do
    content =
      body
      |> get_in(["choices", Access.at(0), "message", "content"])
      |> to_string()

    usage = Map.get(body, "usage", %{})
    model = Map.get(body, "model", "unknown")

    {:ok,
     %{
       content: content,
       model: model,
       usage: usage,
       metadata: %{raw_response: body}
     }}
  end

  defp parse_response(_), do: {:error, "Invalid response format"}

  defp parse_stream_chunk(chunk) when is_binary(chunk) do
    # SSE format: "data: {...}\n\n"
    with "data: " <> json_str <- String.trim(chunk),
         {:ok, data} <- Jason.decode(json_str) do
      delta = get_in(data, ["choices", Access.at(0), "delta", "content"]) || ""
      done = get_in(data, ["choices", Access.at(0), "finish_reason"]) != nil

      %{content: delta, done: done, metadata: data}
    else
      _ -> %{content: "", done: false, metadata: %{}}
    end
  end

  defp valid_endpoint?(endpoint) do
    String.starts_with?(endpoint, "https://api.deepseek.com")
  end

  defp valid_model?(model) when is_binary(model) do
    model in ["deepseek-chat", "deepseek-reasoner"]
  end

  defp valid_model?(_), do: false
end

defmodule Ragex.AI.Registry do
  @moduledoc """
  Convenience wrapper for AI provider registry operations.

  This module provides a simpler API by delegating to `Ragex.AI.Provider.Registry`.

  ## Usage

      alias Ragex.AI.Registry

      # Get provider module
      {:ok, provider} = Registry.get_provider(:deepseek_r1)

      # List all providers
      providers = Registry.list()

      # Get current active provider
      current = Registry.current()
  """

  alias Ragex.AI.Provider.Registry, as: ProviderRegistry

  @doc """
  Get provider module by name.

  Retrieves a registered AI provider module from the registry.

  ## Parameters
  - `provider_name`: Provider identifier atom (e.g., `:deepseek_r1`, `:openai`, `:anthropic`)

  ## Returns
  - `{:ok, module}` - Provider module if registered
  - `{:error, :not_found}` - Provider not found in registry

  ## Examples

      # Get DeepSeek R1 provider
      {:ok, DeepSeekR1} = Registry.get_provider(:deepseek_r1)

      # Try to get unregistered provider
      {:error, :not_found} = Registry.get_provider(:unknown)

      # Use the provider module
      {:ok, provider} = Registry.get_provider(:deepseek_r1)
      {:ok, response} = provider.generate("Explain code", context, opts)
  """
  @spec get_provider(atom()) :: {:ok, module()} | {:error, :not_found}
  def get_provider(provider_name) do
    ProviderRegistry.get_provider(provider_name)
  end

  @doc """
  Register a new provider module.

  ## Parameters
  - `provider_name`: Provider identifier atom
  - `provider_module`: Module implementing `Ragex.AI.Behaviour`

  ## Examples

      Registry.register(:custom_provider, MyApp.CustomProvider)
  """
  @spec register(atom(), module()) :: :ok
  def register(provider_name, provider_module) do
    ProviderRegistry.register(provider_name, provider_module)
  end

  @doc """
  List all registered providers.

  ## Returns
  - Map of provider_name => provider_module

  ## Examples

      providers = Registry.list()
      # => %{deepseek_r1: Ragex.AI.Provider.DeepSeekR1, ...}
  """
  @spec list() :: %{atom() => module()}
  def list do
    ProviderRegistry.list()
  end

  @doc """
  Get the current active provider module from configuration.

  Returns the provider module configured as the default in application config.

  ## Returns
  - Provider module (e.g., `Ragex.AI.Provider.DeepSeekR1`)

  ## Examples

      current = Registry.current()
      {:ok, response} = current.generate("query", context, [])
  """
  @spec current() :: module()
  def current do
    ProviderRegistry.current()
  end

  @doc """
  Get provider module by name, with fallback to configured default.

  If the specified provider is not found, returns the default provider
  configured in the application config.

  ## Parameters
  - `provider_name`: Provider identifier atom (optional)

  ## Returns
  - `{:ok, module}` - Provider module

  ## Examples

      # Get specific provider with fallback
      {:ok, provider} = Registry.get_provider_or_default(:openai)

      # Get default provider
      {:ok, provider} = Registry.get_provider_or_default(nil)
  """
  @spec get_provider_or_default(atom() | nil) :: {:ok, module()}
  def get_provider_or_default(nil) do
    {:ok, current()}
  end

  def get_provider_or_default(provider_name) do
    case get_provider(provider_name) do
      {:ok, module} -> {:ok, module}
      {:error, :not_found} -> {:ok, current()}
    end
  end
end

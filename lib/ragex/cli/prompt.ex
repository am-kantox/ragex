defmodule Ragex.CLI.Prompt do
  @moduledoc """
  Interactive prompt utilities for CLI input.

  Provides functions for getting user input, confirmations, and selections
  from the command line.
  """

  alias Ragex.CLI.Colors

  @doc """
  Prompts the user for a yes/no confirmation.

  Returns `true` for yes, `false` for no.

  ## Options

  - `:default` - Default value if user presses enter (:yes, :no, or nil)

  ## Examples

      iex> Prompt.confirm("Delete file?")
      Delete file? (y/n): y
      true

      iex> Prompt.confirm("Continue?", default: :yes)
      Continue? (Y/n): 
      true
  """
  @spec confirm(String.t(), keyword()) :: boolean()
  def confirm(message, opts \\ []) do
    default = Keyword.get(opts, :default)

    prompt =
      case default do
        :yes -> "#{message} (Y/n): "
        :no -> "#{message} (y/N): "
        _ -> "#{message} (y/n): "
      end

    IO.write(Colors.info(prompt))

    case IO.gets("") |> String.trim() |> String.downcase() do
      "" when default == :yes ->
        true

      "" when default == :no ->
        false

      "y" ->
        true

      "yes" ->
        true

      "n" ->
        false

      "no" ->
        false

      _ ->
        IO.puts(Colors.error("Invalid input. Please enter 'y' or 'n'."))
        confirm(message, opts)
    end
  end

  @doc """
  Prompts the user for text input.

  ## Options

  - `:default` - Default value if user presses enter
  - `:required` - Whether input is required (default: false)
  - `:validate` - Validation function that returns {:ok, value} or {:error, reason}
  - `:mask` - Mask input (for passwords, default: false)

  ## Examples

      iex> Prompt.input("Enter your name")
      Enter your name: Alice
      "Alice"

      iex> Prompt.input("API Key", mask: true)
      API Key: ****
      "secret"
  """
  @spec input(String.t(), keyword()) :: String.t()
  def input(message, opts \\ []) do
    default = Keyword.get(opts, :default)
    required = Keyword.get(opts, :required, false)
    validate_fn = Keyword.get(opts, :validate)
    mask = Keyword.get(opts, :mask, false)

    prompt =
      if default do
        "#{message} (#{Colors.muted(default)}): "
      else
        "#{message}: "
      end

    IO.write(Colors.info(prompt))

    value =
      if mask do
        get_masked_input()
      else
        IO.gets("") |> String.trim()
      end

    value = if value == "" and default, do: default, else: value

    cond do
      required and value == "" ->
        IO.puts(Colors.error("Input is required."))
        input(message, opts)

      validate_fn ->
        case validate_fn.(value) do
          {:ok, validated} ->
            validated

          {:error, reason} ->
            IO.puts(Colors.error("Validation failed: #{reason}"))
            input(message, opts)
        end

      true ->
        value
    end
  end

  @doc """
  Prompts the user to select from a list of options.

  Returns the selected value.

  ## Options

  - `:default` - Index of default option (0-based)
  - `:display_fn` - Function to format option display (default: to_string)

  ## Examples

      iex> Prompt.select("Choose a color", ["Red", "Green", "Blue"])
      Choose a color:
        1. Red
        2. Green
        3. Blue
      Select (1-3): 2
      "Green"
  """
  @spec select(String.t(), [any()], keyword()) :: any()
  def select(message, [_ | _] = options, opts \\ []) do
    default = Keyword.get(opts, :default)
    display_fn = Keyword.get(opts, :display_fn, &to_string/1)

    IO.puts(Colors.info(message))

    options
    |> Enum.with_index(1)
    |> Enum.each(fn {option, idx} ->
      prefix = if default && default == idx - 1, do: Colors.highlight(">"), else: " "
      IO.puts("  #{prefix} #{idx}. #{display_fn.(option)}")
    end)

    max_option = length(options)

    prompt =
      if default do
        "Select (1-#{max_option}) [#{default + 1}]: "
      else
        "Select (1-#{max_option}): "
      end

    IO.write(Colors.info(prompt))

    case IO.gets("") |> String.trim() do
      "" when is_integer(default) ->
        Enum.at(options, default)

      input ->
        case Integer.parse(input) do
          {num, ""} when num >= 1 and num <= max_option ->
            Enum.at(options, num - 1)

          _ ->
            IO.puts(
              Colors.error(
                "Invalid selection. Please enter a number between 1 and #{max_option}."
              )
            )

            select(message, options, opts)
        end
    end
  end

  @doc """
  Prompts the user to select multiple items from a list.

  Returns a list of selected values.

  ## Options

  - `:min` - Minimum number of selections required (default: 0)
  - `:max` - Maximum number of selections allowed (default: unlimited)
  - `:display_fn` - Function to format option display (default: to_string)

  ## Examples

      iex> Prompt.multi_select("Choose toppings", ["Cheese", "Pepperoni", "Olives"])
      Choose toppings (enter numbers separated by commas, or 'all'):
        1. Cheese
        2. Pepperoni
        3. Olives
      Select: 1,3
      ["Cheese", "Olives"]
  """
  @spec multi_select(String.t(), [any()], keyword()) :: [any()]
  def multi_select(message, [_ | _] = options, opts \\ []) do
    min_selections = Keyword.get(opts, :min, 0)
    max_selections = Keyword.get(opts, :max, length(options))
    display_fn = Keyword.get(opts, :display_fn, &to_string/1)

    IO.puts(Colors.info(message <> " (enter numbers separated by commas, or 'all'):"))

    options
    |> Enum.with_index(1)
    |> Enum.each(fn {option, idx} ->
      IO.puts("  #{idx}. #{display_fn.(option)}")
    end)

    IO.write(Colors.info("Select: "))

    case IO.gets("") |> String.trim() |> String.downcase() do
      "all" ->
        options

      input ->
        indices =
          input
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.flat_map(fn num_str ->
            case Integer.parse(num_str) do
              {num, ""} when num >= 1 and num <= length(options) -> [num - 1]
              _ -> []
            end
          end)
          |> Enum.uniq()

        cond do
          length(indices) < min_selections ->
            IO.puts(Colors.error("Please select at least #{min_selections} item(s)."))
            multi_select(message, options, opts)

          length(indices) > max_selections ->
            IO.puts(Colors.error("Please select at most #{max_selections} item(s)."))
            multi_select(message, options, opts)

          true ->
            Enum.map(indices, fn idx -> Enum.at(options, idx) end)
        end
    end
  end

  @doc """
  Prompts the user to enter a number.

  ## Options

  - `:min` - Minimum allowed value
  - `:max` - Maximum allowed value
  - `:default` - Default value
  - `:type` - Number type (:integer or :float, default: :integer)

  ## Examples

      iex> Prompt.number("Enter count", min: 1, max: 100)
      Enter count (1-100): 42
      42
  """
  @spec number(String.t(), keyword()) :: integer() | float()
  def number(message, opts \\ []) do
    min_value = Keyword.get(opts, :min)
    max_value = Keyword.get(opts, :max)
    default = Keyword.get(opts, :default)
    number_type = Keyword.get(opts, :type, :integer)

    range_str =
      case {min_value, max_value} do
        {nil, nil} -> ""
        {min, nil} -> " (min: #{min})"
        {nil, max} -> " (max: #{max})"
        {min, max} -> " (#{min}-#{max})"
      end

    prompt =
      if default do
        "#{message}#{range_str} [#{default}]: "
      else
        "#{message}#{range_str}: "
      end

    IO.write(Colors.info(prompt))

    input = IO.gets("") |> String.trim()
    input = if input == "" and default, do: to_string(default), else: input

    parsed =
      case number_type do
        :float -> Float.parse(input)
        :integer -> Integer.parse(input)
      end

    case parsed do
      {num, ""} ->
        cond do
          min_value && num < min_value ->
            IO.puts(Colors.error("Value must be at least #{min_value}."))
            number(message, opts)

          max_value && num > max_value ->
            IO.puts(Colors.error("Value must be at most #{max_value}."))
            number(message, opts)

          true ->
            num
        end

      _ ->
        IO.puts(Colors.error("Invalid number format."))
        number(message, opts)
    end
  end

  @doc """
  Pauses execution and waits for user to press Enter.

  ## Examples

      iex> Prompt.pause("Press Enter to continue...")
      Press Enter to continue...
      :ok
  """
  @spec pause(String.t()) :: :ok
  def pause(message \\ "Press Enter to continue...") do
    IO.write(Colors.muted(message))
    IO.gets("")
    :ok
  end

  # Private helpers

  defp get_masked_input do
    # Note: This is a simple implementation. For production use,
    # consider using a library that properly handles terminal echo control.
    pid = spawn(fn -> mask_input_loop() end)
    result = IO.gets("") |> String.trim()
    Process.exit(pid, :normal)
    IO.write("\n")
    result
  end

  defp mask_input_loop do
    IO.write("*")

    receive do
      _ -> :ok
    after
      100 -> :ok
    end

    mask_input_loop()
  end
end

defmodule Ragex.CLI.Output do
  @moduledoc """
  Rich output formatting utilities for tables, lists, and structured data.

  Provides functions to render tabular data, lists, and other formatted
  output for the CLI.
  """

  alias Ragex.CLI.Colors

  @type table_row :: [String.t() | number()]
  @type alignment :: :left | :right | :center

  @doc """
  Renders a table with headers and rows.

  ## Options

  - `:alignments` - List of alignments for each column (default: all :left)
  - `:borders` - Whether to draw borders (default: true)
  - `:padding` - Space between columns (default: 2)

  ## Examples

      iex> Output.table(["Name", "Age"], [["Alice", 30], ["Bob", 25]])
      # Renders:
      # Name   | Age
      # -------|-----
      # Alice  | 30
      # Bob    | 25
  """
  @spec table([String.t()], [table_row()], keyword()) :: :ok
  def table(headers, rows, opts \\ []) do
    alignments = Keyword.get(opts, :alignments, List.duplicate(:left, length(headers)))
    borders = Keyword.get(opts, :borders, true)
    padding = Keyword.get(opts, :padding, 2)

    # Convert all cells to strings
    headers = Enum.map(headers, &to_string/1)
    rows = Enum.map(rows, fn row -> Enum.map(row, &to_string/1) end)

    # Calculate column widths
    col_widths = calculate_column_widths([headers | rows])

    # Render table
    if borders do
      render_header(headers, col_widths, padding)
      render_separator(col_widths, padding)
    else
      render_row(headers, col_widths, alignments, padding, bold: true)
    end

    Enum.each(rows, fn row ->
      render_row(row, col_widths, alignments, padding)
    end)

    :ok
  end

  @doc """
  Renders a simple list with bullets.

  ## Options

  - `:bullet` - Bullet character (default: "•")
  - `:indent` - Indentation level (default: 0)
  - `:color` - Color function to apply (default: nil)

  ## Examples

      iex> Output.list(["Item 1", "Item 2", "Item 3"])
      # Renders:
      # • Item 1
      # • Item 2
      # • Item 3
  """
  @spec list([String.t()], keyword()) :: :ok
  def list(items, opts \\ []) do
    bullet = Keyword.get(opts, :bullet, "•")
    indent = Keyword.get(opts, :indent, 0)
    color_fn = Keyword.get(opts, :color)

    Enum.each(items, fn item ->
      line = String.duplicate(" ", indent) <> bullet <> " " <> item
      output = if color_fn, do: color_fn.(line), else: line
      IO.puts(output)
    end)

    :ok
  end

  @doc """
  Renders a key-value list.

  ## Options

  - `:separator` - Separator between key and value (default: ": ")
  - `:indent` - Indentation level (default: 0)
  - `:key_width` - Fixed width for keys (default: auto)
  - `:key_color` - Color for keys (default: :cyan)

  ## Examples

      iex> Output.key_value([{"Name", "Alice"}, {"Age", "30"}])
      # Renders:
      # Name: Alice
      # Age:  30
  """
  @spec key_value([{String.t(), String.t()}], keyword()) :: :ok
  def key_value(pairs, opts \\ []) do
    separator = Keyword.get(opts, :separator, ": ")
    indent = Keyword.get(opts, :indent, 0)
    key_width = Keyword.get(opts, :key_width)
    key_color = Keyword.get(opts, :key_color, :cyan)

    # Calculate max key width if not specified
    max_key_width = key_width || Enum.map(pairs, fn {k, _v} -> String.length(k) end) |> Enum.max()

    Enum.each(pairs, fn {key, value} ->
      padded_key = String.pad_trailing(key, max_key_width)
      colored_key = Colors.colorize(padded_key, key_color)
      line = String.duplicate(" ", indent) <> colored_key <> separator <> to_string(value)
      IO.puts(line)
    end)

    :ok
  end

  @doc """
  Renders a section header with optional underline.

  ## Options

  - `:underline` - Character for underline (default: "=")
  - `:color` - Color for header (default: :cyan)

  ## Examples

      iex> Output.section("Statistics")
      # Renders:
      # Statistics
      # ==========
  """
  @spec section(String.t(), keyword()) :: :ok
  def section(title, opts \\ []) do
    underline_char = Keyword.get(opts, :underline, "=")
    color = Keyword.get(opts, :color, :cyan)

    colored_title = Colors.colorize(title, color, :bright)
    IO.puts("\n" <> colored_title)

    if underline_char do
      IO.puts(String.duplicate(underline_char, String.length(title)))
    end

    IO.puts("")
    :ok
  end

  @doc """
  Renders a horizontal separator line.

  ## Options

  - `:char` - Character to use (default: "-")
  - `:width` - Line width (default: 80)
  - `:color` - Color for line (default: nil)

  ## Examples

      iex> Output.separator()
      # Renders:
      # --------------------------------------------------------------------------------
  """
  @spec separator(keyword()) :: :ok
  def separator(opts \\ []) do
    char = Keyword.get(opts, :char, "-")
    width = Keyword.get(opts, :width, 80)
    color_fn = Keyword.get(opts, :color)

    line = String.duplicate(char, width)
    output = if color_fn, do: color_fn.(line), else: line
    IO.puts(output)
    :ok
  end

  @doc """
  Renders a formatted diff with colors.

  ## Examples

      iex> Output.diff([{:add, "new line"}, {:delete, "old line"}, {:context, "same"}])
      # Renders with colors:
      # + new line (green)
      # - old line (red)
      #   same (muted)
  """
  @spec diff([{:add | :delete | :context, String.t()}]) :: :ok
  def diff(lines) do
    Enum.each(lines, fn
      {:add, text} -> IO.puts(Colors.diff_add(text))
      {:delete, text} -> IO.puts(Colors.diff_delete(text))
      {:context, text} -> IO.puts(Colors.diff_context(text))
    end)

    :ok
  end

  @doc """
  Renders a progress summary with statistics.

  ## Examples

      iex> Output.summary(%{total: 100, success: 95, errors: 5, duration: 1.5})
      # Renders formatted summary with colors
  """
  @spec summary(map()) :: :ok
  def summary(stats) do
    section("Summary")

    pairs = [
      {"Total", Map.get(stats, :total, 0)},
      {"Success", Colors.success(to_string(Map.get(stats, :success, 0)))},
      {"Errors",
       if(Map.get(stats, :errors, 0) > 0,
         do: Colors.error(to_string(Map.get(stats, :errors, 0))),
         else: "0"
       )},
      {"Duration", format_duration(Map.get(stats, :duration, 0))}
    ]

    key_value(pairs, indent: 2)
    :ok
  end

  # Private helpers

  defp calculate_column_widths(rows) do
    if Enum.empty?(rows) do
      []
    else
      num_cols = length(hd(rows))

      for col_idx <- 0..(num_cols - 1) do
        rows
        |> Enum.map(fn row -> Enum.at(row, col_idx) || "" end)
        |> Enum.map(&String.length/1)
        |> Enum.max()
      end
    end
  end

  defp render_header(headers, widths, padding) do
    render_row(headers, widths, List.duplicate(:left, length(headers)), padding, bold: true)
  end

  defp render_separator(widths, padding) do
    sep_parts =
      Enum.map(widths, fn width ->
        String.duplicate("-", width)
      end)

    sep_line =
      Enum.join(
        sep_parts,
        String.duplicate(" ", padding - 1) <> "|" <> String.duplicate(" ", padding - 1)
      )

    IO.puts(Colors.muted(sep_line))
  end

  defp render_row(cells, widths, alignments, padding, opts \\ []) do
    bold = Keyword.get(opts, :bold, false)

    padded_cells =
      Enum.zip([cells, widths, alignments])
      |> Enum.map(fn {cell, width, alignment} ->
        pad_cell(cell, width, alignment)
      end)

    line = Enum.join(padded_cells, String.duplicate(" ", padding))
    output = if bold, do: Colors.bold(line), else: line
    IO.puts(output)
  end

  defp pad_cell(cell, width, :left), do: String.pad_trailing(cell, width)
  defp pad_cell(cell, width, :right), do: String.pad_leading(cell, width)

  defp pad_cell(cell, width, :center) do
    total_padding = width - String.length(cell)
    left_padding = div(total_padding, 2)
    right_padding = total_padding - left_padding
    String.duplicate(" ", left_padding) <> cell <> String.duplicate(" ", right_padding)
  end

  defp format_duration(seconds) when is_float(seconds) do
    cond do
      seconds < 1.0 ->
        "#{Float.round(seconds * 1000, 1)}ms"

      seconds < 60.0 ->
        "#{Float.round(seconds, 2)}s"

      true ->
        minutes = div(trunc(seconds), 60)
        secs = rem(trunc(seconds), 60)
        "#{minutes}m #{secs}s"
    end
  end

  defp format_duration(seconds) when is_integer(seconds) do
    format_duration(seconds / 1.0)
  end

  defp format_duration(_), do: "N/A"
end

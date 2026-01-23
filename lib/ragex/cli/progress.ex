defmodule Ragex.CLI.Progress do
  @moduledoc """
  Progress bar and spinner utilities for CLI operations.

  Provides visual feedback for long-running operations with progress bars,
  spinners, and status indicators.
  """

  alias Ragex.CLI.Colors

  @spinner_frames ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
  @bar_filled "█"
  @bar_empty "░"

  @doc """
  Renders a progress bar.

  ## Options

  - `:width` - Width of the progress bar (default: 40)
  - `:show_percent` - Show percentage (default: true)
  - `:show_fraction` - Show current/total (default: true)
  - `:label` - Label to display before the bar (default: nil)
  - `:complete_char` - Character for completed portion (default: "█")
  - `:incomplete_char` - Character for incomplete portion (default: "░")

  ## Examples

      iex> Progress.bar(50, 100, label: "Processing")
      Processing [████████████████████░░░░░░░░░░░░░░░░░░░░] 50% (50/100)
  """
  @spec bar(non_neg_integer(), pos_integer(), keyword()) :: :ok
  def bar(current, total, opts \\ []) do
    width = Keyword.get(opts, :width, 40)
    show_percent = Keyword.get(opts, :show_percent, true)
    show_fraction = Keyword.get(opts, :show_fraction, true)
    label = Keyword.get(opts, :label)
    complete_char = Keyword.get(opts, :complete_char, @bar_filled)
    incomplete_char = Keyword.get(opts, :incomplete_char, @bar_empty)

    # Calculate progress
    percent = if total > 0, do: current / total, else: 0.0
    filled = round(percent * width)
    empty = width - filled

    # Build bar
    colored_bar =
      Colors.colorize(String.duplicate(complete_char, filled), :green) <>
        Colors.muted(String.duplicate(incomplete_char, empty))

    # Build components
    parts = []
    parts = if label, do: [label <> " " | parts], else: parts
    parts = ["[" <> colored_bar <> "]" | parts]
    parts = if show_percent, do: [" #{Float.round(percent * 100, 1)}%" | parts], else: parts
    parts = if show_fraction, do: [" (#{current}/#{total})" | parts], else: parts

    # Clear line and render
    IO.write("\r" <> Enum.join(Enum.reverse(parts)))
    if current >= total, do: IO.write("\n")

    :ok
  end

  @doc """
  Starts a spinner for an indeterminate operation.

  Returns a PID that can be used to stop the spinner.

  ## Options

  - `:label` - Label to display next to spinner (default: nil)
  - `:frames` - Custom spinner frames (default: unicode spinner)
  - `:interval` - Milliseconds between frames (default: 80)

  ## Examples

      iex> pid = Progress.spinner(label: "Loading")
      iex> # Do work...
      iex> Progress.stop_spinner(pid, "Done!")
  """
  @spec spinner(keyword()) :: pid()
  def spinner(opts \\ []) do
    label = Keyword.get(opts, :label)
    frames = Keyword.get(opts, :frames, @spinner_frames)
    interval = Keyword.get(opts, :interval, 80)

    spawn(fn ->
      spinner_loop(frames, label, interval, 0)
    end)
  end

  @doc """
  Stops a running spinner and displays completion message.

  ## Examples

      iex> pid = Progress.spinner(label: "Loading")
      iex> Progress.stop_spinner(pid, "Complete!")
  """
  @spec stop_spinner(pid(), String.t() | nil) :: :ok
  def stop_spinner(pid, message \\ nil) do
    ref = Process.monitor(pid)
    Process.exit(pid, :kill)

    # Wait for process to die
    receive do
      {:DOWN, ^ref, :process, ^pid, _} -> :ok
    after
      100 -> :ok
    end

    # Clear line
    IO.write("\r\e[K")
    if message, do: IO.puts(message)
    :ok
  end

  @doc """
  Displays a simple status message with icon.

  ## Options

  - `:status` - Status type (:success, :error, :warning, :info)

  ## Examples

      iex> Progress.status("All tests passed", status: :success)
      ✓ All tests passed

      iex> Progress.status("Warning: deprecated function", status: :warning)
      ⚠ Warning: deprecated function
  """
  @spec status(String.t(), keyword()) :: :ok
  def status(message, opts \\ []) do
    status_type = Keyword.get(opts, :status, :info)

    {icon, color_fn} =
      case status_type do
        :success -> {"✓", &Colors.success/1}
        :error -> {"✗", &Colors.error/1}
        :warning -> {"⚠", &Colors.warning/1}
        :info -> {"ℹ", &Colors.info/1}
        _ -> {"•", & &1}
      end

    IO.puts(color_fn.("#{icon} #{message}"))
    :ok
  end

  @doc """
  Renders a multi-step progress indicator.

  ## Examples

      iex> Progress.steps(["Parse", "Analyze", "Generate"], 1)
      [✓] Parse
      [→] Analyze
      [ ] Generate
  """
  @spec steps([String.t()], non_neg_integer()) :: :ok
  def steps(step_names, current_step) do
    step_names
    |> Enum.with_index()
    |> Enum.each(fn {name, idx} ->
      icon =
        cond do
          idx < current_step -> Colors.success("[✓]")
          idx == current_step -> Colors.info("[→]")
          true -> Colors.muted("[ ]")
        end

      text = if idx == current_step, do: Colors.bold(name), else: name
      IO.puts("#{icon} #{text}")
    end)

    :ok
  end

  @doc """
  Displays a percentage-based progress update.

  ## Examples

      iex> Progress.percent(75, label: "Upload")
      Upload: 75%
  """
  @spec percent(number(), keyword()) :: :ok
  def percent(percentage, opts \\ []) do
    label = Keyword.get(opts, :label)

    colored_percent =
      cond do
        percentage >= 100 -> Colors.success("#{percentage}%")
        percentage >= 75 -> Colors.info("#{percentage}%")
        percentage >= 50 -> Colors.warning("#{percentage}%")
        true -> "#{percentage}%"
      end

    output = if label, do: "#{label}: #{colored_percent}", else: colored_percent
    IO.write("\r#{output}")
    if percentage >= 100, do: IO.write("\n")

    :ok
  end

  @doc """
  Renders a task list with status indicators.

  ## Examples

      iex> Progress.task_list([
      ...>   {"Fetch data", :done},
      ...>   {"Process", :running},
      ...>   {"Save", :pending}
      ...> ])
  """
  @spec task_list([{String.t(), :done | :running | :pending | :error}]) :: :ok
  def task_list(tasks) do
    Enum.each(tasks, fn {task_name, status} ->
      {icon, color_fn} =
        case status do
          :done -> {"✓", &Colors.success/1}
          :running -> {"→", &Colors.info/1}
          :pending -> {"◦", &Colors.muted/1}
          :error -> {"✗", &Colors.error/1}
        end

      IO.puts(color_fn.("#{icon} #{task_name}"))
    end)

    :ok
  end

  # Private helpers

  defp spinner_loop(frames, label, interval, frame_index) do
    frame = Enum.at(frames, rem(frame_index, length(frames)))

    output =
      if label do
        Colors.info(frame) <> " " <> label
      else
        Colors.info(frame)
      end

    IO.write("\r#{output}")

    receive do
      _ -> :ok
    after
      interval -> :ok
    end

    spinner_loop(frames, label, interval, frame_index + 1)
  end
end

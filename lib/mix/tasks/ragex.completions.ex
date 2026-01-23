defmodule Mix.Tasks.Ragex.Completions do
  @moduledoc """
  Install shell completion scripts for Ragex.

  ## Usage

      # Show completion scripts and installation instructions
      mix ragex.completions
      
      # Install for your shell
      mix ragex.completions --install
      
      # Install for specific shell
      mix ragex.completions --install --shell bash
      mix ragex.completions --install --shell zsh
      mix ragex.completions --install --shell fish

  Supports bash, zsh, and fish shells with intelligent auto-completion
  for Mix tasks, options, and arguments.
  """

  @shortdoc "Install shell completion scripts"

  use Mix.Task

  alias Ragex.CLI.{Colors, Output}

  @completions_dir Path.join(:code.priv_dir(:ragex), "completions")

  @shells [:bash, :zsh, :fish]

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        switches: [install: :boolean, shell: :string, help: :boolean],
        aliases: [i: :install, s: :shell, h: :help]
      )

    cond do
      opts[:help] ->
        show_help()

      opts[:install] ->
        shell =
          if opts[:shell] do
            String.to_atom(opts[:shell])
          else
            detect_shell()
          end

        install_completions(shell)

      true ->
        show_completions()
    end
  end

  defp show_completions do
    Output.section("Ragex Shell Completions")

    IO.puts(Colors.muted("Available completion scripts for:"))
    IO.puts("")

    for shell <- @shells do
      IO.puts("  • #{Colors.info(to_string(shell))}")
    end

    IO.puts("")
    IO.puts(Colors.bold("Installation:"))
    IO.puts("")

    show_installation_instructions()

    IO.puts("")
    IO.puts(Colors.muted("Or use: #{Colors.highlight("mix ragex.completions --install")}"))
    IO.puts("")
  end

  defp show_installation_instructions do
    IO.puts(Colors.info("Bash:"))
    IO.puts("  sudo cp #{@completions_dir}/ragex.bash /etc/bash_completion.d/")
    IO.puts("  Or: source #{@completions_dir}/ragex.bash in ~/.bashrc")
    IO.puts("")

    IO.puts(Colors.info("Zsh:"))

    IO.puts(
      "  Copy to fpath: cp #{@completions_dir}/ragex.zsh /usr/local/share/zsh/site-functions/_ragex"
    )

    IO.puts("  Then: compinit")
    IO.puts("")

    IO.puts(Colors.info("Fish:"))
    IO.puts("  cp #{@completions_dir}/ragex.fish ~/.config/fish/completions/")
    IO.puts("")
  end

  defp detect_shell do
    shell_env = System.get_env("SHELL", "")

    cond do
      String.contains?(shell_env, "bash") -> :bash
      String.contains?(shell_env, "zsh") -> :zsh
      String.contains?(shell_env, "fish") -> :fish
      true -> :bash
    end
  end

  defp install_completions(shell) when shell in @shells do
    Output.section("Install #{String.upcase(to_string(shell))} Completions")

    source_file = Path.join(@completions_dir, "ragex.#{shell}")

    unless File.exists?(source_file) do
      IO.puts(Colors.error("✗ Completion script not found: #{source_file}"))
      IO.puts("")
      System.halt(1)
    end

    dest_file =
      case shell do
        :bash -> "/etc/bash_completion.d/ragex"
        :zsh -> "/usr/local/share/zsh/site-functions/_ragex"
        :fish -> Path.expand("~/.config/fish/completions/ragex.fish")
      end

    IO.puts(Colors.info("Source: #{source_file}"))
    IO.puts(Colors.info("Destination: #{dest_file}"))
    IO.puts("")

    # Check if destination directory exists
    dest_dir = Path.dirname(dest_file)

    unless File.dir?(dest_dir) do
      IO.puts(Colors.warning("⚠ Directory does not exist: #{dest_dir}"))

      if shell == :fish do
        IO.puts(Colors.info("Creating directory..."))
        File.mkdir_p!(dest_dir)
        IO.puts(Colors.success("✓ Created: #{dest_dir}"))
        IO.puts("")
      else
        IO.puts(Colors.error("✗ Installation requires sudo privileges"))
        IO.puts("")
        IO.puts("Run manually:")
        IO.puts(Colors.highlight("  sudo mkdir -p #{dest_dir}"))
        IO.puts(Colors.highlight("  sudo cp #{source_file} #{dest_file}"))
        IO.puts("")
        System.halt(1)
      end
    end

    # Attempt to copy
    case File.cp(source_file, dest_file) do
      :ok ->
        IO.puts(Colors.success("✓ Completion script installed successfully"))
        IO.puts("")
        show_activation_instructions(shell)

      {:error, :eacces} ->
        IO.puts(Colors.error("✗ Permission denied"))
        IO.puts("")
        IO.puts("Run with sudo:")
        IO.puts(Colors.highlight("  sudo cp #{source_file} #{dest_file}"))
        IO.puts("")
        System.halt(1)

      {:error, reason} ->
        IO.puts(Colors.error("✗ Installation failed: #{inspect(reason)}"))
        IO.puts("")
        System.halt(1)
    end
  end

  defp install_completions(shell) do
    IO.puts(Colors.error("✗ Unknown shell: #{shell}"))
    IO.puts("")
    IO.puts("Supported shells: #{Enum.join(@shells, ", ")}")
    IO.puts("")
    System.halt(1)
  end

  defp show_activation_instructions(:bash) do
    IO.puts(Colors.bold("Activation:"))
    IO.puts("  1. Restart your shell or run:")
    IO.puts(Colors.highlight("     source #{@completions_dir}/ragex.bash"))
    IO.puts("  2. Try: #{Colors.highlight("mix ragex.<TAB>")}")
    IO.puts("")
  end

  defp show_activation_instructions(:zsh) do
    IO.puts(Colors.bold("Activation:"))
    IO.puts("  1. Run: #{Colors.highlight("compinit")}")
    IO.puts("  2. Or restart your shell")
    IO.puts("  3. Try: #{Colors.highlight("mix ragex.<TAB>")}")
    IO.puts("")
  end

  defp show_activation_instructions(:fish) do
    IO.puts(Colors.bold("Activation:"))
    IO.puts("  1. Completions are active immediately")
    IO.puts("  2. Try: #{Colors.highlight("mix ragex.<TAB>")}")
    IO.puts("")
  end

  defp show_help do
    IO.puts("""
    #{Colors.bold("Ragex Shell Completions")}

    #{Colors.info("Show available completions:")}
      mix ragex.completions

    #{Colors.info("Auto-detect and install:")}
      mix ragex.completions --install

    #{Colors.info("Install for specific shell:")}
      mix ragex.completions --install --shell bash
      mix ragex.completions --install --shell zsh
      mix ragex.completions --install --shell fish

    #{Colors.info("Supported shells:")}
      • bash - Bash shell
      • zsh  - Z shell
      • fish - Friendly Interactive Shell

    #{Colors.muted("Completions provide auto-complete for task names, options, and arguments.")}
    """)
  end
end

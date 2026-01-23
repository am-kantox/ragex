defmodule Ragex.CLI.ColorsTest do
  use ExUnit.Case, async: true

  alias Ragex.CLI.Colors

  describe "enabled?/0" do
    test "returns false when NO_COLOR is set" do
      System.put_env("NO_COLOR", "1")
      refute Colors.enabled?()
      System.delete_env("NO_COLOR")
    end

    test "returns false when TERM is dumb" do
      original = System.get_env("TERM")
      System.put_env("TERM", "dumb")
      refute Colors.enabled?()
      if original, do: System.put_env("TERM", original), else: System.delete_env("TERM")
    end
  end

  describe "success/1" do
    test "returns colored text when colors enabled" do
      result = Colors.success("Done")
      assert String.contains?(result, "Done")
    end

    test "handles non-string input" do
      result = Colors.success(123)
      assert is_binary(result)
    end
  end

  describe "error/1" do
    test "returns colored text for errors" do
      result = Colors.error("Failed")
      assert String.contains?(result, "Failed")
    end
  end

  describe "warning/1" do
    test "returns colored text for warnings" do
      result = Colors.warning("Careful")
      assert String.contains?(result, "Careful")
    end
  end

  describe "info/1" do
    test "returns colored text for info" do
      result = Colors.info("Processing")
      assert String.contains?(result, "Processing")
    end
  end

  describe "highlight/1" do
    test "returns highlighted text" do
      result = Colors.highlight("Important")
      assert String.contains?(result, "Important")
    end
  end

  describe "muted/1" do
    test "returns muted text" do
      result = Colors.muted("Optional")
      assert String.contains?(result, "Optional")
    end
  end

  describe "colorize/3" do
    test "colorizes text with custom color and style" do
      result = Colors.colorize("Custom", :magenta, :italic)
      assert String.contains?(result, "Custom")
    end

    test "handles missing style parameter" do
      result = Colors.colorize("Text", :blue)
      assert String.contains?(result, "Text")
    end

    test "converts non-strings to strings" do
      result = Colors.colorize(42, :red)
      assert String.contains?(result, "42")
    end
  end

  describe "bold/1" do
    test "returns bold text" do
      result = Colors.bold("Bold")
      assert String.contains?(result, "Bold")
    end
  end

  describe "underline/1" do
    test "returns underlined text" do
      result = Colors.underline("Link")
      assert String.contains?(result, "Link")
    end
  end

  describe "diff functions" do
    test "diff_add/1 adds + prefix" do
      result = Colors.diff_add("new line")
      assert String.contains?(result, "+ new line")
    end

    test "diff_delete/1 adds - prefix" do
      result = Colors.diff_delete("old line")
      assert String.contains?(result, "- old line")
    end

    test "diff_context/1 adds space prefix" do
      result = Colors.diff_context("context")
      assert String.contains?(result, "  context")
    end
  end

  describe "NO_COLOR support" do
    setup do
      System.put_env("NO_COLOR", "1")
      on_exit(fn -> System.delete_env("NO_COLOR") end)
    end

    test "success/1 returns plain text when colors disabled" do
      result = Colors.success("Done")
      assert result == "Done"
      refute String.contains?(result, "\e[")
    end

    test "error/1 returns plain text when colors disabled" do
      result = Colors.error("Failed")
      assert result == "Failed"
      refute String.contains?(result, "\e[")
    end

    test "colorize/3 returns plain text when colors disabled" do
      result = Colors.colorize("Text", :blue, :bold)
      assert result == "Text"
      refute String.contains?(result, "\e[")
    end
  end
end

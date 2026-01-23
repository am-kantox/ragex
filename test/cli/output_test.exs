defmodule Ragex.CLI.OutputTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  alias Ragex.CLI.Output

  describe "table/3" do
    test "renders table with headers and rows" do
      output =
        capture_io(fn ->
          Output.table(["Name", "Age"], [["Alice", 30], ["Bob", 25]])
        end)

      assert output =~ "Name"
      assert output =~ "Age"
      assert output =~ "Alice"
      assert output =~ "Bob"
      assert output =~ "30"
      assert output =~ "25"
    end

    test "renders table without borders" do
      output =
        capture_io(fn ->
          Output.table(["Col1", "Col2"], [["A", "B"]], borders: false)
        end)

      assert output =~ "Col1"
      assert output =~ "Col2"
      refute output =~ "|"
    end

    test "handles empty rows" do
      output =
        capture_io(fn ->
          Output.table(["Header"], [])
        end)

      assert output =~ "Header"
    end

    test "handles numeric values" do
      output =
        capture_io(fn ->
          Output.table(["Count"], [[42], [100]])
        end)

      assert output =~ "42"
      assert output =~ "100"
    end
  end

  describe "list/2" do
    test "renders list with default bullet" do
      output =
        capture_io(fn ->
          Output.list(["Item 1", "Item 2", "Item 3"])
        end)

      assert output =~ "• Item 1"
      assert output =~ "• Item 2"
      assert output =~ "• Item 3"
    end

    test "renders list with custom bullet" do
      output =
        capture_io(fn ->
          Output.list(["A", "B"], bullet: "-")
        end)

      assert output =~ "- A"
      assert output =~ "- B"
    end

    test "renders list with indentation" do
      output =
        capture_io(fn ->
          Output.list(["Nested"], indent: 4)
        end)

      assert output =~ "    •"
    end
  end

  describe "key_value/2" do
    test "renders key-value pairs" do
      output =
        capture_io(fn ->
          Output.key_value([{"Name", "Alice"}, {"Age", "30"}])
        end)

      assert output =~ "Name"
      assert output =~ "Alice"
      assert output =~ "Age"
      assert output =~ "30"
    end

    test "aligns keys to same width" do
      output =
        capture_io(fn ->
          Output.key_value([{"Short", "A"}, {"VeryLongKey", "B"}])
        end)

      assert output =~ "Short"
      assert output =~ "VeryLongKey"
    end

    test "uses custom separator" do
      output =
        capture_io(fn ->
          Output.key_value([{"Key", "Value"}], separator: " = ")
        end)

      assert output =~ "Key = Value"
    end
  end

  describe "section/2" do
    test "renders section with underline" do
      output =
        capture_io(fn ->
          Output.section("Statistics")
        end)

      assert output =~ "Statistics"
      assert output =~ "=========="
    end

    test "renders section without underline" do
      output =
        capture_io(fn ->
          Output.section("Title", underline: nil)
        end)

      assert output =~ "Title"
      refute output =~ "===="
    end

    test "uses custom underline character" do
      output =
        capture_io(fn ->
          Output.section("Test", underline: "-")
        end)

      assert output =~ "----"
    end
  end

  describe "separator/1" do
    test "renders horizontal line with default width" do
      output =
        capture_io(fn ->
          Output.separator()
        end)

      assert String.length(String.trim(output)) >= 80
    end

    test "renders line with custom width" do
      output =
        capture_io(fn ->
          Output.separator(width: 20)
        end)

      assert String.length(String.trim(output)) == 20
    end

    test "uses custom character" do
      output =
        capture_io(fn ->
          Output.separator(char: "=", width: 10)
        end)

      assert output =~ "=========="
    end
  end

  describe "diff/1" do
    test "renders diff lines with colors" do
      output =
        capture_io(fn ->
          Output.diff([
            {:add, "new line"},
            {:delete, "old line"},
            {:context, "same"}
          ])
        end)

      assert output =~ "+ new line"
      assert output =~ "- old line"
      assert output =~ "  same"
    end

    test "handles empty diff" do
      output =
        capture_io(fn ->
          Output.diff([])
        end)

      assert output == ""
    end
  end

  describe "summary/1" do
    test "renders summary with statistics" do
      output =
        capture_io(fn ->
          Output.summary(%{
            total: 100,
            success: 95,
            errors: 5,
            duration: 1.5
          })
        end)

      assert output =~ "Summary"
      assert output =~ "Total"
      assert output =~ "100"
      assert output =~ "Success"
      assert output =~ "95"
      assert output =~ "Errors"
      assert output =~ "5"
      assert output =~ "Duration"
    end

    test "handles zero errors" do
      output =
        capture_io(fn ->
          Output.summary(%{
            total: 10,
            success: 10,
            errors: 0
          })
        end)

      assert output =~ "Errors"
      assert output =~ "0"
    end

    test "formats duration correctly" do
      # Milliseconds
      output1 =
        capture_io(fn ->
          Output.summary(%{duration: 0.5})
        end)

      assert output1 =~ "500"
      assert output1 =~ "ms"

      # Seconds
      output2 =
        capture_io(fn ->
          Output.summary(%{duration: 5.25})
        end)

      assert output2 =~ "5.25"
      assert output2 =~ "s"

      # Minutes
      output3 =
        capture_io(fn ->
          Output.summary(%{duration: 125})
        end)

      assert output3 =~ "2m"
    end
  end
end

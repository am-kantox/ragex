defmodule Ragex.Analyzers.ElixirTest do
  use ExUnit.Case, async: true

  alias Ragex.Analyzers.Elixir, as: ElixirAnalyzer

  describe "analyze/2" do
    test "extracts module information" do
      source = """
      defmodule TestModule do
        def hello, do: :world
      end
      """

      assert {:ok, result} = ElixirAnalyzer.analyze(source, "test.ex")
      assert [module] = result.modules
      assert module.name == TestModule
      assert module.file == "test.ex"
      assert module.line == 1
    end

    test "extracts function information" do
      source = """
      defmodule TestModule do
        def public_function(arg1, arg2) do
          :ok
        end

        defp private_function do
          :private
        end
      end
      """

      assert {:ok, result} = ElixirAnalyzer.analyze(source, "test.ex")
      assert Enum.count(result.functions) == 2

      public_func = Enum.find(result.functions, &(&1.name == :public_function))
      assert public_func.arity == 2
      assert public_func.visibility == :public
      assert public_func.module == TestModule

      private_func = Enum.find(result.functions, &(&1.name == :private_function))
      assert private_func.arity == 0
      assert private_func.visibility == :private
    end

    test "extracts import information" do
      source = """
      defmodule TestModule do
        import Enum
        require Logger
        use GenServer
        alias MyApp.Helper
      end
      """

      assert {:ok, result} = ElixirAnalyzer.analyze(source, "test.ex")
      assert Enum.count(result.imports) == 4

      assert Enum.any?(result.imports, &(&1.type == :import && &1.to_module == Enum))
      assert Enum.any?(result.imports, &(&1.type == :require && &1.to_module == Logger))
      assert Enum.any?(result.imports, &(&1.type == :use && &1.to_module == GenServer))
      assert Enum.any?(result.imports, &(&1.type == :alias && &1.to_module == MyApp.Helper))
    end

    test "extracts function calls" do
      source = """
      defmodule TestModule do
        def caller do
          String.upcase("test")
        end
      end
      """

      assert {:ok, result} = ElixirAnalyzer.analyze(source, "test.ex")
      assert result.calls != []

      call = Enum.find(result.calls, &(&1.to_function == :upcase))
      assert call.to_module == String
      assert call.from_function == :caller
    end

    test "handles syntax errors" do
      source = """
      defmodule TestModule
        def broken
      end
      """

      assert {:error, _} = ElixirAnalyzer.analyze(source, "test.ex")
    end
  end

  describe "supported_extensions/0" do
    test "returns elixir file extensions" do
      assert [".ex", ".exs"] = ElixirAnalyzer.supported_extensions()
    end
  end

  describe "documentation extraction" do
    test "extracts @moduledoc" do
      source = """
      defmodule DocumentedModule do
        @moduledoc "This is a documented module"

        def hello, do: :world
      end
      """

      assert {:ok, result} = ElixirAnalyzer.analyze(source, "test.ex")
      assert [module] = result.modules
      assert module.name == DocumentedModule
      assert module.doc == "This is a documented module"
    end

    test "extracts multi-line @moduledoc with heredoc" do
      source = """
      defmodule MultiLineDoc do
        @moduledoc \"\"\"       
        This is a multi-line module documentation.

        It can span multiple lines and include examples.
        \"\"\"

        def test, do: :ok
      end
      """

      assert {:ok, result} = ElixirAnalyzer.analyze(source, "test.ex")
      assert [module] = result.modules
      assert module.name == MultiLineDoc
      assert is_binary(module.doc)
      assert String.contains?(module.doc, "multi-line")
      assert String.contains?(module.doc, "examples")
    end

    test "extracts @doc for functions" do
      source = """
      defmodule TestModule do
        @doc "Greets the world"
        def hello do
          :world
        end

        @doc "Says goodbye"
        def goodbye do
          :bye
        end
      end
      """

      assert {:ok, result} = ElixirAnalyzer.analyze(source, "test.ex")
      assert Enum.count(result.functions) == 2

      hello_func = Enum.find(result.functions, &(&1.name == :hello))
      assert hello_func.doc == "Greets the world"

      goodbye_func = Enum.find(result.functions, &(&1.name == :goodbye))
      assert goodbye_func.doc == "Says goodbye"
    end

    test "handles @doc false" do
      source = """
      defmodule TestModule do
        @doc false
        def private_impl do
          :hidden
        end
      end
      """

      assert {:ok, result} = ElixirAnalyzer.analyze(source, "test.ex")
      assert [func] = result.functions
      assert func.doc == nil
    end

    test "handles @moduledoc false" do
      source = """
      defmodule TestModule do
        @moduledoc false

        def hello, do: :world
      end
      """

      assert {:ok, result} = ElixirAnalyzer.analyze(source, "test.ex")
      assert [module] = result.modules
      assert module.doc == nil
    end

    test "handles mixed documented and undocumented functions" do
      source = """
      defmodule TestModule do
        @doc "This is documented"
        def documented do
          :ok
        end

        def undocumented do
          :ok
        end

        @doc "Also documented"
        def another_documented do
          :ok
        end
      end
      """

      assert {:ok, result} = ElixirAnalyzer.analyze(source, "test.ex")
      assert Enum.count(result.functions) == 3

      documented = Enum.find(result.functions, &(&1.name == :documented))
      assert documented.doc == "This is documented"

      undocumented = Enum.find(result.functions, &(&1.name == :undocumented))
      assert undocumented.doc == nil

      another = Enum.find(result.functions, &(&1.name == :another_documented))
      assert another.doc == "Also documented"
    end

    test "handles module without any documentation" do
      source = """
      defmodule UndocumentedModule do
        def hello, do: :world
      end
      """

      assert {:ok, result} = ElixirAnalyzer.analyze(source, "test.ex")
      assert [module] = result.modules
      assert module.doc == nil
      assert [func] = result.functions
      assert func.doc == nil
    end

    test "handles multiple consecutive @doc attributes (last one wins)" do
      source = """
      defmodule TestModule do
        @doc "First doc"
        @doc "Second doc"
        def hello, do: :world
      end
      """

      assert {:ok, result} = ElixirAnalyzer.analyze(source, "test.ex")
      assert [func] = result.functions
      # Last @doc wins
      assert func.doc == "Second doc"
    end

    test "clears pending doc between functions" do
      source = """
      defmodule TestModule do
        @doc "First function"
        def first, do: :ok

        def second, do: :ok
      end
      """

      assert {:ok, result} = ElixirAnalyzer.analyze(source, "test.ex")
      assert Enum.count(result.functions) == 2

      first = Enum.find(result.functions, &(&1.name == :first))
      assert first.doc == "First function"

      second = Enum.find(result.functions, &(&1.name == :second))
      assert second.doc == nil
    end
  end
end

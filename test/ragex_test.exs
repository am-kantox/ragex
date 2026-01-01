defmodule RagexTest do
  use ExUnit.Case
  doctest Ragex

  test "returns stats" do
    stats = Ragex.stats()
    assert is_map(stats)
    assert Map.has_key?(stats, :nodes)
    assert Map.has_key?(stats, :edges)
  end
end

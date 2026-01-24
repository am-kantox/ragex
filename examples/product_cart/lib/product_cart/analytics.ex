defmodule ProductCart.Analytics do
  @moduledoc """
  Analytics tracking - stub for demo.
  """

  def track_product_creation(_name, _category, _price) do
    %{id: :erlang.unique_integer([:positive])}
  end
end

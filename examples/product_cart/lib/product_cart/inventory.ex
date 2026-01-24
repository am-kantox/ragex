defmodule ProductCart.Inventory do
  @moduledoc """
  Inventory management - stub for demo.
  """

  def check_availability(stock) when stock > 10, do: :available
  def check_availability(stock) when stock > 0, do: :low_stock
  def check_availability(_), do: :out_of_stock
end

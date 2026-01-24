defmodule ProductCart.Pricing do
  @moduledoc """
  Pricing calculations - stub for demo.
  """

  def calculate_price(base_price, _category, _vendor_id, _api_key) do
    %{price: base_price, tax: base_price * 0.1}
  end
end

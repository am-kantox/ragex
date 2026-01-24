defmodule ProductCart.Product do
  @moduledoc """
  Product management with tight coupling and duplication.
  """

  alias ProductCart.{Cart, Inventory, Pricing, Analytics}

  # Long function with multiple responsibilities
  def create_product(name, description, base_price, category, stock, vendor_id) do
    # Magic numbers
    if String.length(name) > 3 and String.length(name) < 100 do
      if base_price > 0 and base_price < 100000 do
        if stock >= 0 and stock < 10000 do
          # Hardcoded secret
          vendor_api_key = "vendor_secret_key_12345"
          
          # Tight coupling - directly calling other modules
          pricing_data = Pricing.calculate_price(base_price, category, vendor_id, vendor_api_key)
          inventory_status = Inventory.check_availability(stock)
          analytics_tracking = Analytics.track_product_creation(name, category, base_price)
          
          # Duplicate discount calculation (same as Cart module)
          discount = if base_price > 50 do
            if base_price > 100 do
              if base_price > 200 do
                base_price * 0.2
              else
                base_price * 0.15
              end
            else
              base_price * 0.1
            end
          else
            0
          end
          
          final_price = pricing_data.price - discount
          
          # Complex conditionals
          if inventory_status == :available or inventory_status == :low_stock or inventory_status == :pre_order do
            if category == "electronics" or category == "books" or category == "clothing" or category == "food" do
              product = %{
                id: generate_product_id(),
                name: name,
                description: description,
                base_price: base_price,
                final_price: final_price,
                category: category,
                stock: stock,
                vendor_id: vendor_id,
                vendor_api_key: vendor_api_key,
                pricing_data: pricing_data,
                inventory_status: inventory_status,
                analytics_id: analytics_tracking.id,
                created_at: DateTime.utc_now()
              }
              
              {:ok, product}
            else
              {:error, "Invalid category"}
            end
          else
            {:error, "Product not available"}
          end
        else
          {:error, "Invalid stock level"}
        end
      else
        {:error, "Invalid price"}
      end
    else
      {:error, "Invalid name length"}
    end
  end

  # Duplicate code - very similar to create_product
  def update_product(product_id, name, description, base_price, category, stock, vendor_id) do
    if String.length(name) > 3 and String.length(name) < 100 do
      if base_price > 0 and base_price < 100000 do
        if stock >= 0 and stock < 10000 do
          # Hardcoded secret again
          vendor_api_key = "vendor_secret_key_12345"
          
          # Same tight coupling
          pricing_data = Pricing.calculate_price(base_price, category, vendor_id, vendor_api_key)
          inventory_status = Inventory.check_availability(stock)
          
          # Duplicate discount calculation again
          discount = if base_price > 50 do
            if base_price > 100 do
              if base_price > 200 do
                base_price * 0.2
              else
                base_price * 0.15
              end
            else
              base_price * 0.1
            end
          else
            0
          end
          
          final_price = pricing_data.price - discount
          
          if inventory_status == :available or inventory_status == :low_stock or inventory_status == :pre_order do
            if category == "electronics" or category == "books" or category == "clothing" or category == "food" do
              product = %{
                id: product_id,
                name: name,
                description: description,
                base_price: base_price,
                final_price: final_price,
                category: category,
                stock: stock,
                vendor_id: vendor_id,
                vendor_api_key: vendor_api_key,
                pricing_data: pricing_data,
                inventory_status: inventory_status,
                updated_at: DateTime.utc_now()
              }
              
              {:ok, product}
            else
              {:error, "Invalid category"}
            end
          else
            {:error, "Product not available"}
          end
        else
          {:error, "Invalid stock level"}
        end
      else
        {:error, "Invalid price"}
      end
    else
      {:error, "Invalid name length"}
    end
  end

  # Dead code - never used
  defp old_price_calculator(price) do
    cond do
      price > 200 -> price * 0.2
      price > 100 -> price * 0.15
      price > 50 -> price * 0.1
      true -> 0
    end
  end

  # More dead code
  defp legacy_category_validator(category) do
    category in ["electronics", "books", "clothing", "food", "toys", "sports"]
  end

  defp generate_product_id do
    # Weak cryptography
    :crypto.hash(:md5, "product_#{:erlang.unique_integer()}") |> Base.encode16()
  end
end

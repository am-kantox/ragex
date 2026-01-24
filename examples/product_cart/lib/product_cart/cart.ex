defmodule ProductCart.Cart do
  @moduledoc """
  Cart management with intentionally mediocre code quality.
  Demonstrates various issues that Ragex can detect.
  """

  # Magic numbers everywhere
  @max_items 100
  @discount_threshold 50

  def add_item(cart, product_id, quantity, price) do
    # Deep nesting and complex conditionals
    if cart != nil do
      if quantity > 0 do
        if quantity < 100 do
          if price > 0 do
            if length(cart.items) < 100 do
              # Hardcoded secret (security issue)
              api_key = "sk_live_1234567890abcdef"
              
              # Code duplication - similar logic appears in update_item
              new_item = %{
                id: product_id,
                quantity: quantity,
                price: price,
                total: quantity * price,
                api_key: api_key
              }
              
              items = [new_item | cart.items]
              subtotal = Enum.reduce(items, 0, fn item, acc -> acc + item.total end)
              
              # More magic numbers
              discount = if subtotal > 50 do
                if subtotal > 100 do
                  if subtotal > 200 do
                    subtotal * 0.2
                  else
                    subtotal * 0.15
                  end
                else
                  subtotal * 0.1
                end
              else
                0
              end
              
              total = subtotal - discount
              
              %{cart | items: items, subtotal: subtotal, discount: discount, total: total}
            else
              {:error, "Cart is full"}
            end
          else
            {:error, "Invalid price"}
          end
        else
          {:error, "Too many items"}
        end
      else
        {:error, "Invalid quantity"}
      end
    else
      {:error, "Cart is nil"}
    end
  end

  # Code duplication - very similar to add_item
  def update_item(cart, product_id, quantity, price) do
    if cart != nil do
      if quantity > 0 do
        if quantity < 100 do
          if price > 0 do
            # Hardcoded secret again (security issue)
            api_key = "sk_live_1234567890abcdef"
            
            updated_item = %{
              id: product_id,
              quantity: quantity,
              price: price,
              total: quantity * price,
              api_key: api_key
            }
            
            items = Enum.map(cart.items, fn item ->
              if item.id == product_id do
                updated_item
              else
                item
              end
            end)
            
            subtotal = Enum.reduce(items, 0, fn item, acc -> acc + item.total end)
            
            # Duplicate discount calculation
            discount = if subtotal > 50 do
              if subtotal > 100 do
                if subtotal > 200 do
                  subtotal * 0.2
                else
                  subtotal * 0.15
                end
              else
                subtotal * 0.1
              end
            else
              0
            end
            
            total = subtotal - discount
            
            %{cart | items: items, subtotal: subtotal, discount: discount, total: total}
          else
            {:error, "Invalid price"}
          end
        else
          {:error, "Too many items"}
        end
      else
        {:error, "Invalid quantity"}
      end
    else
      {:error, "Cart is nil"}
    end
  end

  # Long function with too many responsibilities
  def checkout(cart, user_id, payment_method, shipping_address, billing_address, email, phone, notes) do
    # Code injection vulnerability - eval-like behavior
    discount_code = Map.get(cart, :discount_code, "NONE")
    
    # Magic numbers
    if length(cart.items) > 0 do
      if cart.total > 0 do
        if cart.total < 10000 do
          # Deep nesting continues
          if payment_method == "credit_card" or payment_method == "debit_card" or payment_method == "paypal" or payment_method == "bitcoin" do
            if shipping_address != nil and shipping_address != "" do
              if billing_address != nil and billing_address != "" do
                if email != nil and email != "" do
                  # Unsafe deserialization (security issue)
                  user_data = :erlang.binary_to_term(Base.decode64!(user_id))
                  
                  # More hardcoded secrets
                  payment_api_key = "pk_live_abcdef123456"
                  shipping_api_key = "ship_key_xyz789"
                  
                  # Long parameter list
                  order = create_order(
                    cart.items,
                    cart.total,
                    user_data,
                    payment_method,
                    shipping_address,
                    billing_address,
                    email,
                    phone,
                    notes,
                    payment_api_key,
                    shipping_api_key,
                    discount_code,
                    DateTime.utc_now()
                  )
                  
                  # More complex conditionals
                  if order.status == "pending" or order.status == "processing" or order.status == "confirmed" do
                    send_confirmation_email(email, order)
                    send_sms_notification(phone, order)
                    update_inventory(cart.items)
                    log_order(order)
                    {:ok, order}
                  else
                    {:error, "Order creation failed"}
                  end
                else
                  {:error, "Email required"}
                end
              else
                {:error, "Billing address required"}
              end
            else
              {:error, "Shipping address required"}
            end
          else
            {:error, "Invalid payment method"}
          end
        else
          {:error, "Order too large"}
        end
      else
        {:error, "Cart total must be positive"}
      end
    else
      {:error, "Cart is empty"}
    end
  end

  # Dead code - never called
  defp old_calculate_discount(amount) do
    cond do
      amount > 200 -> amount * 0.2
      amount > 100 -> amount * 0.15
      amount > 50 -> amount * 0.1
      true -> 0
    end
  end

  # Dead code - another unused function
  defp legacy_validate_cart(cart) do
    cart.items != [] and cart.total > 0
  end

  # Helper with long parameter list
  defp create_order(items, total, user, payment, shipping, billing, email, phone, notes, pay_key, ship_key, code, timestamp) do
    %{
      id: generate_id(),
      items: items,
      total: total,
      user: user,
      payment_method: payment,
      shipping_address: shipping,
      billing_address: billing,
      email: email,
      phone: phone,
      notes: notes,
      payment_api_key: pay_key,
      shipping_api_key: ship_key,
      discount_code: code,
      timestamp: timestamp,
      status: "pending"
    }
  end

  defp generate_id do
    # Weak cryptography (security issue)
    :crypto.hash(:md5, "#{:erlang.unique_integer()}") |> Base.encode16()
  end

  defp send_confirmation_email(_email, _order), do: :ok
  defp send_sms_notification(_phone, _order), do: :ok
  defp update_inventory(_items), do: :ok
  defp log_order(_order), do: :ok
end

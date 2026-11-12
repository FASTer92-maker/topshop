require "test_helper"

class CartItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:customer)
    @variant = variants(:men_jacket_m_black)
  end

  test "guest is asked to sign in" do
    assert_no_difference -> { CartItem.count } do
      post cart_items_path, params: { variant_id: @variant.id, quantity: 1 }
    end

    assert_redirected_to new_session_path
  end

  test "create adds the variant and opens the cart page" do
    sign_in_as @user

    assert_difference -> { carts(:customer_cart).cart_items.count }, 1 do
      post cart_items_path, params: { variant_id: @variant.id }
    end

    assert_redirected_to cart_path
    follow_redirect!

    assert_response :success
    assert_select "#cart_counter", text: /Корзина \(1\)/
    assert_select "#cart_item_#{CartItem.last.id}", text: /Куртка «Арден»/
    assert_equal "Товар добавлен в корзину", flash[:notice]
  end

  test "create uses the given quantity" do
    sign_in_as @user

    post cart_items_path, params: { variant_id: @variant.id, quantity: 2 }

    assert_equal 2, carts(:customer_cart).cart_items.find_by!(variant: @variant).quantity

    follow_redirect!
    assert_select "#cart_counter", text: /Корзина \(2\)/
  end

  test "create twice increases the quantity of one row" do
    sign_in_as @user

    assert_difference -> { CartItem.count }, 1 do
      post cart_items_path, params: { variant_id: @variant.id }
      post cart_items_path, params: { variant_id: @variant.id }
    end

    assert_equal 1, carts(:customer_cart).cart_items.count
    assert_equal 2, carts(:customer_cart).cart_items.find_by!(variant: @variant).quantity
  end

  test "create answers turbo stream requests with the cart page redirect" do
    sign_in_as @user

    post cart_items_path, params: { variant_id: @variant.id }, as: :turbo_stream

    assert_redirected_to cart_path
  end

  test "create without a variant returns the size error" do
    sign_in_as @user

    assert_no_difference -> { CartItem.count } do
      post cart_items_path, as: :turbo_stream
    end

    assert_response :unprocessable_content
    assert_select "turbo-stream[action=replace][target=flash]"
    assert_match "Выберите размер", response.body
  end

  test "create rejects a quantity above the stock" do
    sign_in_as @user

    assert_no_difference -> { CartItem.count } do
      post cart_items_path, params: { variant_id: variants(:men_jacket_m_tabacco).id, quantity: 3 },
                            as: :turbo_stream
    end

    assert_response :unprocessable_content
    assert_match "Недостаточно товара на складе (доступно: 2)", response.body
  end

  test "create rejects an out-of-stock variant" do
    sign_in_as @user

    post cart_items_path, params: { variant_id: variants(:sold_out_bag_one_size).id }, as: :turbo_stream

    assert_response :unprocessable_content
    assert_match "Недостаточно товара на складе (доступно: 0)", response.body
  end

  test "create rejects a variant of a hidden product" do
    sign_in_as @user

    post cart_items_path, params: { variant_id: variants(:hidden_bag_one_size).id }, as: :turbo_stream

    assert_response :unprocessable_content
    assert_match "Товар недоступен", response.body
  end

  test "an unknown variant is treated as no size chosen" do
    sign_in_as @user

    post cart_items_path, params: { variant_id: 0 }, as: :turbo_stream

    assert_response :unprocessable_content
    assert_match "Выберите размер", response.body
  end

  test "html errors keep the user on the page with an alert" do
    sign_in_as @user

    post cart_items_path

    assert_redirected_to cart_path
    assert_equal "Выберите размер", flash[:alert]
  end

  test "update changes the quantity and refreshes the cart contents" do
    item = cart_item!
    sign_in_as @user

    patch cart_item_path(item), params: { quantity: 2 }, as: :turbo_stream

    assert_response :success
    assert_equal 2, item.reload.quantity
    assert_select "turbo-stream[action=replace][target=cart_contents]"
    assert_select "turbo-stream[action=replace][target=cart_counter]"
    assert_match(/Корзина \(2\)/, response.body)
  end

  test "update to zero removes the item" do
    item = cart_item!
    sign_in_as @user

    assert_difference -> { CartItem.count }, -1 do
      patch cart_item_path(item), params: { quantity: 0 }, as: :turbo_stream
    end

    assert_response :success
    assert_match "Товар удалён из корзины", response.body
    assert_match(/Корзина \(0\)/, response.body)
    assert_match "Корзина пуста.", response.body
  end

  test "update above the stock keeps the quantity and shows an error" do
    item = cart_item!(variant: variants(:men_jacket_m_tabacco), quantity: 2)
    sign_in_as @user

    patch cart_item_path(item), params: { quantity: 3 }, as: :turbo_stream

    assert_response :unprocessable_content
    assert_equal 2, item.reload.quantity
    assert_match "Недостаточно товара на складе (доступно: 2)", response.body
  end

  test "update with a blank quantity returns an error" do
    item = cart_item!
    sign_in_as @user

    patch cart_item_path(item), params: { quantity: "" }, as: :turbo_stream

    assert_response :unprocessable_content
    assert_equal 1, item.reload.quantity
    assert_match "Некорректное количество", response.body
  end

  test "destroy removes the item" do
    item = cart_item!
    sign_in_as @user

    assert_difference -> { CartItem.count }, -1 do
      delete cart_item_path(item), as: :turbo_stream
    end

    assert_response :success
    assert_match "Товар удалён из корзины", response.body
    assert_match "Корзина пуста.", response.body
  end

  test "html update redirects back to the cart" do
    item = cart_item!
    sign_in_as @user

    patch cart_item_path(item), params: { quantity: 2 }

    assert_redirected_to cart_path
  end

  test "another user's item is not found" do
    item = carts(:other_customer_cart).cart_items.create!(variant: @variant, quantity: 1)
    sign_in_as @user

    assert_no_difference -> { CartItem.count } do
      patch cart_item_path(item), params: { quantity: 2 }, as: :turbo_stream
    end

    assert_response :not_found
  end

  test "an unknown item is not found" do
    sign_in_as @user

    patch cart_item_path(0), params: { quantity: 2 }, as: :turbo_stream

    assert_response :not_found
  end

  test "guest cannot change the cart" do
    item = cart_item!

    assert_no_difference -> { CartItem.count } do
      patch cart_item_path(item), params: { quantity: 2 }
      delete cart_item_path(item)
    end

    assert_redirected_to new_session_path
  end

  private
    def cart_item!(variant: @variant, quantity: 1)
      carts(:customer_cart).cart_items.create!(variant: variant, quantity: quantity)
    end
end

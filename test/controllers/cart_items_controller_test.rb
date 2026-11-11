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

  test "create adds the variant and replaces the counter and the flash" do
    sign_in_as @user

    assert_difference -> { carts(:customer_cart).cart_items.count }, 1 do
      post cart_items_path, params: { variant_id: @variant.id }, as: :turbo_stream
    end

    assert_response :success
    assert_select "turbo-stream[action=replace][target=cart_counter]"
    assert_match(/id="cart_counter"[^>]*>Корзина \(1\)</, response.body)
    assert_match "Товар добавлен в корзину", response.body
  end

  test "create uses the given quantity" do
    sign_in_as @user

    post cart_items_path, params: { variant_id: @variant.id, quantity: 2 }, as: :turbo_stream

    assert_equal 2, carts(:customer_cart).cart_items.find_by!(variant: @variant).quantity
    assert_match(/Корзина \(2\)/, response.body)
  end

  test "create twice increases the quantity of one row" do
    sign_in_as @user

    assert_difference -> { CartItem.count }, 1 do
      post cart_items_path, params: { variant_id: @variant.id }, as: :turbo_stream
      post cart_items_path, params: { variant_id: @variant.id }, as: :turbo_stream
    end

    assert_equal 1, carts(:customer_cart).cart_items.count
    assert_equal 2, carts(:customer_cart).cart_items.find_by!(variant: @variant).quantity
    assert_match(/Корзина \(2\)/, response.body)
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

  test "create answers html requests with a redirect" do
    sign_in_as @user

    post cart_items_path, params: { variant_id: @variant.id }

    assert_redirected_to root_path
    assert_equal "Товар добавлен в корзину", flash[:notice]
  end

  test "html errors keep the user on the page with an alert" do
    sign_in_as @user

    post cart_items_path

    assert_redirected_to root_path
    assert_equal "Выберите размер", flash[:alert]
  end
end

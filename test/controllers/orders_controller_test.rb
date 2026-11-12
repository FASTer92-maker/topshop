require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:customer)
    @variant = variants(:men_jacket_m_black)
  end

  test "guest is asked to sign in" do
    get new_order_path
    assert_redirected_to new_session_path

    get orders_path
    assert_redirected_to new_session_path

    get order_path(1)
    assert_redirected_to new_session_path
  end

  test "new redirects to the cart when it is empty" do
    sign_in_as @user

    get new_order_path

    assert_redirected_to cart_path
    assert_equal "Корзина пуста — добавьте товары перед оформлением.", flash[:alert]
  end

  test "new redirects to the cart when an item is unavailable" do
    carts(:customer_cart).add_variant(@variant, 2)
    @variant.update!(stock: 1)
    sign_in_as @user

    get new_order_path

    assert_redirected_to cart_path
    assert_match "Исправьте количество", flash[:alert]
  end

  test "new prefills the name and shows the order composition" do
    carts(:customer_cart).add_variant(@variant, 2)
    sign_in_as @user

    get new_order_path

    assert_response :success
    assert_select "h1", text: "Оформление заказа"
    assert_select "turbo-frame#checkout"
    assert_select "input[name='order[full_name]'][value='Иван Петров']"
    assert_select "input[type=submit][data-turbo-submits-with]"
    assert_select "#checkout_summary" do
      assert_select "p", text: "Куртка «Арден»"
      assert_select "p", text: /M · Чёрный · 2 шт\./
      assert_select "dd", text: /25[[:space:]]980/
      assert_select "dd", text: "Бесплатно"
      assert_select "dd", text: /25[[:space:]]980/
    end
  end

  test "create places the order, clears the cart and opens the order page" do
    carts(:customer_cart).add_variant(@variant, 2)
    sign_in_as @user

    assert_difference -> { Order.count }, 1 do
      post orders_path, params: { order: order_params }
    end

    order = Order.last
    assert_redirected_to order_path(order)
    assert_equal "Заказ оформлен", flash[:notice]
    assert_equal 3, @variant.reload.stock
    assert_equal 0, carts(:customer_cart).cart_items.count

    follow_redirect!
    assert_response :success
    assert_select "h1", text: "Заказ принят"
    assert_match "Оплата имитируется", response.body
    assert_match order.number, response.body
    assert_select "li", text: /Куртка «Арден»/
    assert_select "li", text: /M · Чёрный · 2 шт\./
    assert_select "dd", text: /25[[:space:]]980/
    assert_select "p", text: "Иван Петров"
    assert_select "p", text: "+7 (999) 123-45-67"
    assert_select "p", text: "Москва, ул. Тверская, 1"
    assert_select "p", text: "Позвонить за час"
  end

  test "create with invalid data renders the form with errors" do
    carts(:customer_cart).add_variant(@variant, 2)
    sign_in_as @user

    assert_no_difference -> { Order.count } do
      post orders_path, params: { order: order_params(phone: "123") }
    end

    assert_response :unprocessable_content
    assert_select "turbo-frame#checkout"
    assert_select "[role=alert]", text: /имеет неверное значение/
    assert_select "input[name='order[full_name]'][value='Иван Петров']"
    assert_select "#checkout_summary", text: /Куртка «Арден»/
    assert_equal 5, @variant.reload.stock
    assert_equal 2, carts(:customer_cart).cart_items.first.quantity
  end

  test "create with insufficient stock redirects to the cart" do
    carts(:customer_cart).add_variant(@variant, 2)
    @variant.update!(stock: 1)
    sign_in_as @user

    assert_no_difference -> { Order.count } do
      post orders_path, params: { order: order_params }
    end

    assert_redirected_to cart_path
    assert_match "Куртка «Арден»", flash[:alert]
    assert_match "доступно: 1", flash[:alert]
    assert_equal 1, @variant.reload.stock
    assert_equal 2, carts(:customer_cart).cart_items.first.quantity
  end

  test "create with an empty cart redirects to the cart" do
    sign_in_as @user

    assert_no_difference -> { Order.count } do
      post orders_path, params: { order: order_params }
    end

    assert_redirected_to cart_path
    assert_equal "Корзина пуста — заказ не был создан.", flash[:alert]
  end

  test "show displays snapshots, totals and delivery data" do
    order = place_order
    sign_in_as @user

    get order_path(order)

    assert_response :success
    assert_select "h1", text: "Заказ принят"
    assert_match "Оплата имитируется", response.body
    assert_match order.number, response.body
    assert_select "li", text: /Куртка «Арден»/
    assert_select "li", text: /M · Чёрный · 1 шт\./
    assert_select "dd", text: /12[[:space:]]990/
    assert_select "dd", text: "Бесплатно"
    assert_select "p", text: "Иван Петров"
    assert_select "p", text: "+7 (999) 123-45-67"
  end

  test "another user's order is not found" do
    other_order = place_order(user: users(:other_customer), variant: variants(:women_jacket_s_black))
    sign_in_as @user

    get order_path(other_order)

    assert_response :not_found
  end

  test "index lists only the current user's orders" do
    own_order = place_order
    other_order = place_order(user: users(:other_customer), variant: variants(:women_jacket_s_black))
    sign_in_as @user

    get orders_path

    assert_response :success
    assert_select "h1", text: "Мои заказы"
    assert_match own_order.number, response.body
    assert_no_match other_order.number, response.body
  end

  test "index shows the empty state without orders" do
    sign_in_as @user

    get orders_path

    assert_response :success
    assert_select "p", text: "Заказов пока нет"
  end

  private
    def order_params(overrides = {})
      {
        full_name: "Иван Петров",
        phone: "+7 (999) 123-45-67",
        address: "Москва, ул. Тверская, 1",
        comment: "Позвонить за час"
      }.merge(overrides)
    end

    def place_order(user: @user, variant: @variant, quantity: 1)
      cart = user.cart!
      cart.add_variant(variant, quantity)
      Order.place_from_cart!(cart, order_params)
    end
end

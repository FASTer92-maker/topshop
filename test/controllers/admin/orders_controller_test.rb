require "test_helper"

class Admin::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @variant = variants(:men_jacket_m_black)
  end

  test "guest is asked to sign in" do
    get admin_orders_path
    assert_redirected_to new_session_path

    get admin_order_path(1)
    assert_redirected_to new_session_path

    patch admin_order_path(1, status: "paid")
    assert_redirected_to new_session_path
  end

  test "customer is denied access to orders" do
    order = place_order

    sign_in_as users(:customer)

    get admin_orders_path
    assert_redirected_to root_path

    get admin_order_path(order)
    assert_redirected_to root_path

    patch admin_order_path(order, status: "paid")
    assert_redirected_to root_path
    assert_equal "pending", order.reload.status
  end

  test "index lists every order with customer, total and status" do
    own_order = place_order
    other_order = place_order(user: users(:other_customer), variant: variants(:women_jacket_s_black))
    own_order.update!(status: :paid)

    sign_in_as users(:admin)

    get admin_orders_path

    assert_response :success
    assert_select "h1", "Заказы"
    assert_select "table tbody tr", count: 2
    assert_select "a[href=?]", admin_order_path(own_order), text: own_order.number
    assert_select "a[href=?]", admin_order_path(other_order), text: other_order.number
    assert_select "p", text: "Иван Петров"
    assert_select "p", text: "Мария Соколова"
    assert_select "td", text: "Оплачен"
  end

  test "index shows a tab for every status and filters by it" do
    paid_order = place_order
    paid_order.update!(status: :paid)
    pending_order = place_order

    sign_in_as users(:admin)

    get admin_orders_path

    assert_select "main nav a", count: 7
    assert_select "main nav a[href=?]", admin_orders_path, text: "Все"
    Order.statuses.each_key do |status|
      assert_select "main nav a[href=?]", admin_orders_path(status: status)
    end

    get admin_orders_path(status: "paid")

    assert_response :success
    assert_select "table tbody tr", count: 1
    assert_select "a", text: paid_order.number
    assert_no_match pending_order.number, response.body
  end

  test "index paginates orders" do
    13.times { |index| create_order(created_at: index.minutes.ago) }

    sign_in_as users(:admin)

    get admin_orders_path

    assert_select "table tbody tr", count: 12
    assert_select "a[href=?]", admin_orders_path(page: 2)

    get admin_orders_path(page: 2)

    assert_select "table tbody tr", count: 1
  end

  test "show displays customer data, composition snapshots and allowed transitions" do
    order = place_order(quantity: 2)

    sign_in_as users(:admin)

    get admin_order_path(order)

    assert_response :success
    assert_select "h1", text: /Заказ №#{order.number}/
    assert_select "p", text: "Иван Петров"
    assert_select "p", text: "ivan@example.com"
    assert_select "p", text: "+7 (999) 123-45-67"
    assert_select "p", text: "Москва, ул. Тверская, 1"
    assert_select "td", text: "Куртка «Арден»"
    assert_select "td", text: "M · Чёрный"
    assert_select "td", text: "2"
    assert_select "td", text: /12[[:space:]]990/
    assert_select "td", text: /25[[:space:]]980/

    assert_select "button", text: "Перевести в «Оплачен»"
    assert_select "button", text: "Отменить заказ"
    assert_select "button", text: "Перевести в «Собран»", count: 0
  end

  test "update moves the order and answers with a turbo stream" do
    order = place_order

    sign_in_as users(:admin)

    patch admin_order_path(order, status: "paid"), as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal "paid", order.reload.status
    assert_match "order_status", response.body
    assert_match "Оплачен", response.body
    assert_match "Перевести в «Собран»", response.body
    assert_match "Статус заказа изменён: Оплачен.", response.body
  end

  test "cancelling an order returns its stock" do
    order = place_order(quantity: 2)
    assert_equal 3, @variant.reload.stock

    sign_in_as users(:admin)

    patch admin_order_path(order, status: "cancelled"), as: :turbo_stream

    assert_response :success
    assert_equal "cancelled", order.reload.status
    assert_equal 5, @variant.reload.stock
    assert_match "Отменён", response.body
    assert_match "смена статуса недоступна", response.body
  end

  test "update rejects a transition that is not allowed" do
    order = place_order

    sign_in_as users(:admin)

    patch admin_order_path(order, status: "delivered"), as: :turbo_stream

    assert_response :unprocessable_content
    assert_equal "pending", order.reload.status
    assert_match "Нельзя перевести заказ", response.body
  end

  test "update rejects an unknown status" do
    order = place_order

    sign_in_as users(:admin)

    patch admin_order_path(order, status: "bogus"), as: :turbo_stream

    assert_response :unprocessable_content
    assert_equal "pending", order.reload.status
    assert_match "Неизвестный статус", response.body
  end

  test "update without turbo streams redirects with a notice" do
    order = place_order

    sign_in_as users(:admin)

    patch admin_order_path(order, status: "paid")

    assert_redirected_to admin_order_path(order)
    assert_equal "Статус заказа изменён: Оплачен.", flash[:notice]
    assert_equal "paid", order.reload.status
  end

  private
    def place_order(user: users(:customer), variant: @variant, quantity: 1)
      cart = user.cart!
      cart.add_variant(variant, quantity)
      Order.place_from_cart!(cart, {
        full_name: user.full_name,
        phone: "+7 (999) 123-45-67",
        address: "Москва, ул. Тверская, 1"
      })
    end

    def create_order(user: users(:customer), status: :pending, created_at: Time.current)
      order = user.orders.new(
        number: "ORD-TEST-#{SecureRandom.hex(3).upcase}",
        full_name: user.full_name,
        phone: "+7 (999) 123-45-67",
        address: "Москва, ул. Тверская, 1",
        subtotal: 1000,
        delivery_price: 400,
        total: 1400,
        status: status,
        created_at: created_at
      )
      order.order_items.build(
        variant: @variant,
        product_name: @variant.product.name,
        size: @variant.size,
        color: @variant.color,
        unit_price: 1000,
        quantity: 1
      )
      order.save!
      order
    end
end

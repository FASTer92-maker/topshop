require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @variant = variants(:men_jacket_m_black)
  end

  test "guest is asked to sign in" do
    get admin_root_path

    assert_redirected_to new_session_path
  end

  test "customer is denied access" do
    sign_in_as users(:customer)

    get admin_root_path

    assert_redirected_to root_path

    follow_redirect!
    assert_select "#flash", text: /Доступ запрещён/
  end

  test "admin sees order, revenue and subscriber statistics" do
    create_order(status: :pending, total: 1000)
    create_order(status: :paid, total: 2000)
    create_order(status: :assembled, total: 3000)
    create_order(status: :cancelled, total: 4000)
    Subscriber.create!(email: "second@example.com")

    sign_in_as users(:admin)

    get admin_root_path

    assert_response :success
    assert_select "h1", "Админ-панель"
    assert_select "main", text: /Добро пожаловать в админ-панель/
    assert_select "[data-stat='pending'] p", text: "1"
    assert_select "[data-stat='paid'] p", text: "1"
    assert_select "[data-stat='assembled'] p", text: "1"
    assert_select "[data-stat='revenue'] p", text: /6[[:space:]]000/
    assert_select "[data-stat='subscribers'] p", text: "2"
  end

  test "admin sees low stock variants with size and colour" do
    sign_in_as users(:admin)

    get admin_root_path

    assert_response :success
    assert_select "#low_stock" do
      assert_select "li", count: 3
      assert_select "li", text: /Куртка «Арден»/
      assert_select "li", text: /M · Табачный/
      assert_select "li", text: /L · Чёрный/
      assert_select "li", text: /Сумка «Пусто»/
      assert_select "li", text: /0 шт\./
      assert_select "li", text: /2 шт\./
    end
  end

  test "admin sees the five most recent orders" do
    orders = 6.times.map { |index| create_order(created_at: index.minutes.ago) }

    sign_in_as users(:admin)

    get admin_root_path

    assert_response :success
    assert_select "#recent_orders tbody tr", count: 5
    assert_select "#recent_orders tbody tr:first-child a", text: orders.first.number
    assert_select "#recent_orders", text: /#{Regexp.escape(orders.last.number)}/, count: 0
  end

  private
    def create_order(user: users(:customer), status: :pending, total: 1000, created_at: Time.current)
      order = user.orders.new(
        number: "ORD-TEST-#{SecureRandom.hex(3).upcase}",
        full_name: user.full_name,
        phone: "+7 (999) 123-45-67",
        address: "Москва, ул. Тверская, 1",
        subtotal: total - 400,
        delivery_price: 400,
        total: total,
        status: status,
        created_at: created_at
      )
      order.order_items.build(
        variant: @variant,
        product_name: @variant.product.name,
        size: @variant.size,
        color: @variant.color,
        unit_price: total - 400,
        quantity: 1
      )
      order.save!
      order
    end
end
